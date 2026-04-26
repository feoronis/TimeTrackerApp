import Foundation
import Observation

@MainActor
@Observable
final class ProjectsViewModel {
    private let projectRepository: ProjectRepository
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let sessionCalculator: SessionCalculator
    private let appEnvironment: AppEnvironment

    private(set) var projects: [Project] = []
    private(set) var projectRows: [ProjectListRow] = []
    private(set) var settings: AppSettings?
    var isEditorPresented = false
    var editorDraft = ProjectDraft()
    var searchText = ""
    var showArchived = true
    var editingProject: Project?
    var errorMessage: String?
    var isDeleteConfirmationPresented = false
    var projectPendingDeletion: Project?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.projectRepository = appEnvironment.projectRepository
        self.sessionRepository = appEnvironment.sessionRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.sessionCalculator = appEnvironment.sessionCalculator
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var visibleRows: [ProjectListRow] {
        projectRows
            .filter { showArchived || $0.isArchived == false }
            .filter { row in
                let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedSearch.isEmpty == false else { return true }
                return row.name.localizedCaseInsensitiveContains(trimmedSearch)
            }
    }

    var colorOptions: [String] {
        ["#7C5CFF", "#5B7CFA", "#5CC47D", "#FFB86B", "#FF7A7A", "#FF7AC3", "#9CA3AF"]
    }

    var iconOptions: [String] {
        ["folder", "hammer", "desktopcomputer", "iphone", "paintpalette", "globe", "cart", "briefcase"]
    }

    func load() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            let sessions = try sessionRepository.fetchAll()
            projectRows = buildProjectRows(projects: projects, sessions: sessions)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentCreateSheet() {
        editingProject = nil
        editorDraft = ProjectDraft()
        isEditorPresented = true
    }

    func presentEditSheet(for project: Project) {
        editingProject = project
        editorDraft = ProjectDraft(project: project)
        isEditorPresented = true
    }

    func requestDeleteEditingProject() {
        guard let editingProject else { return }
        projectPendingDeletion = editingProject
        isDeleteConfirmationPresented = true
    }

    func deletePendingProject() {
        guard let projectPendingDeletion else { return }

        do {
            let linkedSessions = try sessionRepository.fetchSessions(projectID: projectPendingDeletion.id)
            try sessionRepository.delete(linkedSessions)
            try projectRepository.delete(projectPendingDeletion)
            try appEnvironment.timerService.restoreActiveSessionIfNeeded()

            if editingProject?.id == projectPendingDeletion.id {
                editingProject = nil
            }

            self.projectPendingDeletion = nil
            isDeleteConfirmationPresented = false
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveProject() {
        let trimmedName = editorDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Название проекта обязательно."
            return
        }

        let hourlyRate = parseOptionalDecimal(editorDraft.hourlyRateText)

        guard editorDraft.hourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hourlyRate != nil else {
            errorMessage = "Ставка должна быть числом."
            return
        }

        do {
            if let editingProject {
                editingProject.name = trimmedName
                editingProject.colorHex = normalizedHex(editorDraft.colorHex)
                editingProject.iconName = editorDraft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                editingProject.hourlyRate = hourlyRate
                editingProject.notes = editorDraft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                editingProject.isArchived = editorDraft.isArchived
                editingProject.updatedAt = .now
                try projectRepository.save()
            } else {
                let project = Project(
                    name: trimmedName,
                    colorHex: normalizedHex(editorDraft.colorHex),
                    iconName: editorDraft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    hourlyRate: hourlyRate,
                    isArchived: editorDraft.isArchived,
                    notes: editorDraft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                )
                try projectRepository.insert(project)
            }

            isEditorPresented = false
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(_ project: Project) {
        do {
            try projectRepository.archive(project)
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unarchive(_ project: Project) {
        do {
            try projectRepository.unarchive(project)
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildProjectRows(projects: [Project], sessions: [WorkSession]) -> [ProjectListRow] {
        projects.map { project in
            let projectSessions = sessions.filter { $0.project?.id == project.id && $0.endTime != nil }
            let totalDuration = projectSessions.reduce(0) { $0 + $1.durationSeconds }
            let totalIncome = projectSessions.reduce(Decimal.zero) { $0 + sessionCalculator.sessionIncome($1) }

            return ProjectListRow(
                id: project.id,
                name: project.name,
                colorHex: project.colorHex,
                iconName: project.iconName ?? "folder",
                hourlyRate: project.hourlyRate,
                totalDurationSeconds: totalDuration,
                totalIncome: totalIncome,
                isArchived: project.isArchived
            )
        }
        .sorted { lhs, rhs in
            if lhs.isArchived != rhs.isArchived {
                return rhs.isArchived == false
            }
            return lhs.totalIncome > rhs.totalIncome
        }
    }

    private func parseOptionalDecimal(_ value: String) -> Decimal? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedValue.isEmpty == false else {
            return nil
        }

        return Decimal(string: trimmedValue.replacingOccurrences(of: ",", with: "."))
    }

    private func normalizedHex(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false else {
            return "#7C5CFF"
        }

        return trimmedValue.hasPrefix("#") ? trimmedValue : "#\(trimmedValue)"
    }
}

struct ProjectListRow: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let iconName: String
    let hourlyRate: Decimal?
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal
    let isArchived: Bool
}
