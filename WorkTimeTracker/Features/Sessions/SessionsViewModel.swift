import Foundation
import Observation

@MainActor
@Observable
final class SessionsViewModel {
    private let sessionRepository: SessionRepository
    private let projectRepository: ProjectRepository
    private let settingsRepository: SettingsRepository
    private let sessionCalculator: SessionCalculator
    private let appEnvironment: AppEnvironment
    private(set) var sessions: [WorkSession] = []
    private(set) var projects: [Project] = []
    private(set) var settings: AppSettings?
    var draft = SessionDraft()
    var editingSession: WorkSession?
    var isEditorPresented = false
    var sessionPendingDeletion: WorkSession?
    var isDeleteConfirmationPresented = false
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.sessionCalculator = appEnvironment.sessionCalculator
    }

    func load() {
        appEnvironment.bootstrap()

        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            sessions = try sessionRepository.fetchAll()
            errorMessage = appEnvironment.bootstrapErrorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentCreateSheet() {
        editingSession = nil
        draft = SessionDraft()
        draft.projectID = projects.first(where: { $0.isArchived == false })?.id
        isEditorPresented = true
    }

    func presentEditSheet(for session: WorkSession) {
        guard session.endTime != nil else {
            errorMessage = "Активную сессию нельзя редактировать, пока работает таймер."
            return
        }

        editingSession = session
        draft = SessionDraft(session: session)
        isEditorPresented = true
    }

    func duplicate(_ session: WorkSession) {
        guard session.endTime != nil else {
            errorMessage = "Активную сессию нельзя дублировать, пока работает таймер."
            return
        }

        editingSession = nil
        draft = SessionDraft(session: session)
        isEditorPresented = true
    }

    func requestDelete(_ session: WorkSession) {
        guard session.endTime != nil else {
            errorMessage = "Активную сессию нельзя удалить, пока работает таймер."
            return
        }

        sessionPendingDeletion = session
        isDeleteConfirmationPresented = true
    }

    func deletePendingSession() {
        guard let sessionPendingDeletion else { return }

        do {
            try sessionRepository.delete(sessionPendingDeletion)
            self.sessionPendingDeletion = nil
            isDeleteConfirmationPresented = false
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDraft() {
        guard draft.endTime >= draft.startTime else {
            errorMessage = "Окончание не может быть раньше начала."
            return
        }

        let trimmedRate = draft.customHourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let customRate = parseOptionalDecimal(trimmedRate)

        guard trimmedRate.isEmpty || customRate != nil else {
            errorMessage = "Ставка должна быть числом."
            return
        }

        guard let settings else {
            errorMessage = "Не удалось загрузить настройки приложения."
            return
        }

        let selectedProject = projects.first { $0.id == draft.projectID }
        let calculatedValues = sessionCalculator.calculateCompletedSessionValues(
            start: draft.startTime,
            end: draft.endTime,
            sessionCustomRate: customRate,
            projectRate: selectedProject?.hourlyRate,
            defaultRate: settings.defaultHourlyRate
        )

        do {
            if let editingSession {
                editingSession.project = selectedProject
                editingSession.startTime = draft.startTime
                editingSession.endTime = draft.endTime
                editingSession.durationSeconds = calculatedValues.durationSeconds
                editingSession.note = sanitizedText(draft.note)
                editingSession.tags = parsedTags(draft.tagsText)
                editingSession.customHourlyRate = customRate
                editingSession.resolvedHourlyRateSnapshot = calculatedValues.resolvedHourlyRateSnapshot
                editingSession.updatedAt = .now
                try sessionRepository.save()
            } else {
                let session = WorkSession(
                    project: selectedProject,
                    startTime: draft.startTime,
                    endTime: draft.endTime,
                    durationSeconds: calculatedValues.durationSeconds,
                    note: sanitizedText(draft.note),
                    tags: parsedTags(draft.tagsText),
                    customHourlyRate: customRate,
                    resolvedHourlyRateSnapshot: calculatedValues.resolvedHourlyRateSnapshot
                )
                try sessionRepository.insert(session)
            }

            isEditorPresented = false
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    func incomeText(for session: WorkSession) -> String {
        AppFormatters.currencyText(
            sessionCalculator.sessionIncome(session),
            currencyCode: currencyCode
        )
    }

    func rateText(for session: WorkSession) -> String {
        AppFormatters.currencyText(
            session.resolvedHourlyRateSnapshot,
            currencyCode: currencyCode
        )
    }

    private func parseOptionalDecimal(_ value: String) -> Decimal? {
        guard value.isEmpty == false else {
            return nil
        }

        return Decimal(string: value.replacingOccurrences(of: ",", with: "."))
    }

    private func sanitizedText(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private func parsedTags(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}
