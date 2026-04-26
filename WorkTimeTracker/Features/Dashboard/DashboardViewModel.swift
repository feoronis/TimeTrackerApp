import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    let timerService: TimerService
    private let sessionCalculator: SessionCalculator
    private let sessionRepository: SessionRepository
    private let projectRepository: ProjectRepository
    private let settingsRepository: SettingsRepository
    private let dayNoteRepository: DayNoteRepository
    private let tagRepository: TagRepository
    private let reportService: ReportService
    private let appEnvironment: AppEnvironment
    private(set) var projects: [Project] = []
    private(set) var recentSessions: [WorkSession] = []
    private(set) var availableTags: [Tag] = []
    private(set) var settings: AppSettings?
    private(set) var todaySummary: DaySummaryReport?
    private(set) var yesterdaySummary: DaySummaryReport?
    var selectedProjectID: UUID?
    var sessionNote = ""
    var selectedTagNames: [String] = []
    var customRateText = ""
    var isCreateTagPresented = false
    var newTagName = ""
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.sessionCalculator = appEnvironment.sessionCalculator
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.dayNoteRepository = appEnvironment.dayNoteRepository
        self.tagRepository = appEnvironment.tagRepository
        self.reportService = appEnvironment.reportService
        self.timerService = appEnvironment.timerService
    }

    var selectedProject: Project? {
        projects.first { $0.id == selectedProjectID }
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var todayIncomeText: String {
        AppFormatters.currencyText(todaySummary?.totalIncome ?? .zero, currencyCode: currencyCode)
    }

    var todayWorkedTimeText: String {
        AppFormatters.compactDurationText(from: todaySummary?.totalDurationSeconds ?? 0)
    }

    var todaySessionCountText: String {
        "\(todaySummary?.sessionCount ?? 0)"
    }

    var mostActiveProjectText: String {
        todaySummary?.mostActiveProjectName ?? "Нет данных"
    }

    var mostActiveProjectDurationText: String {
        guard let duration = todaySummary?.projectRows.first?.totalDurationSeconds else {
            return "Нет активности"
        }

        return AppFormatters.compactDurationText(from: duration)
    }

    var todayWorkedDeltaText: String {
        AppFormatters.comparisonDurationText(
            (todaySummary?.totalDurationSeconds ?? 0) - (yesterdaySummary?.totalDurationSeconds ?? 0)
        ) + " к вчера"
    }

    var todayIncomeDeltaText: String {
        AppFormatters.comparisonCurrencyText(
            (todaySummary?.totalIncome ?? .zero) - (yesterdaySummary?.totalIncome ?? .zero),
            currencyCode: currencyCode
        ) + " к вчера"
    }

    var todaySessionDeltaText: String {
        let delta = (todaySummary?.sessionCount ?? 0) - (yesterdaySummary?.sessionCount ?? 0)
        let prefix = delta >= 0 ? "+" : "−"
        return "\(prefix)\(abs(delta)) к вчера"
    }

    var effectiveRateText: String {
        AppFormatters.currencyText(currentResolvedRate, currencyCode: currencyCode) + "/ч"
    }

    var rateFieldValueText: String {
        let customRate = timerService.activeSession?.customHourlyRate ?? parseOptionalDecimal(customRateText)
        let value = customRate ?? currentResolvedRate
        return AppFormatters.currencyText(value, currencyCode: currencyCode)
    }

    var hasCustomRateOverride: Bool {
        timerService.activeSession?.customHourlyRate != nil || parseOptionalDecimal(customRateText) != nil
    }

    var activeTimerDurationText: String {
        AppFormatters.durationText(from: currentElapsedDuration)
    }

    var activeTimerIncomeText: String {
        AppFormatters.currencyText(currentTimerIncome, currencyCode: currencyCode)
    }

    var suggestedTags: [DashboardTagSuggestion] {
        let recentTags = recentSessions.flatMap(\.tags)
        let tags = (availableTags.map(\.name) + recentTags).orderedUnique()
        let activeTags = Set(selectedTagNames)

        return tags.enumerated().map { index, tag in
            DashboardTagSuggestion(
                title: tag,
                colorHex: DashboardTagSuggestion.palette[tag] ?? DashboardTagSuggestion.defaultPalette[index % DashboardTagSuggestion.defaultPalette.count],
                isSelected: activeTags.contains(tag)
            )
        }
    }

    func load() {
        appEnvironment.bootstrap()
        reloadData()
    }

    func reloadData() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll(includeArchived: false)
            recentSessions = try sessionRepository.fetchRecent(limit: 8)
            availableTags = try tagRepository.fetchAll()
            let allSessions = try sessionRepository.fetchAll()
            let today = Date.now
            todaySummary = reportService.buildDaySummary(
                sessions: allSessions,
                selectedDate: today,
                dayNote: try dayNoteRepository.fetch(for: today)
            )

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
            yesterdaySummary = reportService.buildDaySummary(
                sessions: allSessions,
                selectedDate: yesterday,
                dayNote: try dayNoteRepository.fetch(for: yesterday)
            )

            if let activeProjectID = timerService.activeSession?.project?.id {
                selectedProjectID = activeProjectID
                customRateText = timerService.activeSession?.customHourlyRate.map(AppFormatters.decimalText) ?? ""
            } else if selectedProjectID == nil {
                selectedProjectID = projects.first?.id
            }

            errorMessage = appEnvironment.bootstrapErrorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startTimer() {
        guard let selectedProject else {
            errorMessage = "Перед запуском таймера выберите проект."
            return
        }

        let trimmedRate = customRateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let customRate = parseOptionalDecimal(trimmedRate)

        guard trimmedRate.isEmpty || customRate != nil else {
            errorMessage = "Своя ставка должна быть числом."
            return
        }

        do {
            try timerService.startTimer(
                project: selectedProject,
                note: sessionNote,
                tags: selectedTagNames,
                customHourlyRate: customRate
            )

            sessionNote = ""
            selectedTagNames = []
            customRateText = ""
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopTimer() {
        do {
            try timerService.stopActiveTimer()
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pauseTimer() {
        do {
            if timerService.activeSession?.isPaused == true {
                try timerService.resumeActiveTimer()
            } else {
                try timerService.pauseActiveTimer()
            }

            errorMessage = nil
            appEnvironment.notifyDataChanged()
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rateEditingText() -> String {
        if customRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return customRateText
        }

        if let activeCustomRate = timerService.activeSession?.customHourlyRate {
            return AppFormatters.decimalText(activeCustomRate)
        }

        if let activeSession = timerService.activeSession {
            return AppFormatters.decimalText(activeSession.resolvedHourlyRateSnapshot)
        }

        return AppFormatters.decimalText(currentResolvedRate)
    }

    func commitCustomRate(_ rawValue: String) {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedRate = parseOptionalDecimal(trimmedValue)

        guard trimmedValue.isEmpty || parsedRate != nil else {
            errorMessage = "Ставка должна быть числом."
            return
        }

        do {
            customRateText = trimmedValue

            if timerService.activeSession != nil {
                try timerService.updateActiveSessionRate(customHourlyRate: parsedRate)
                appEnvironment.notifyDataChanged()
            }

            errorMessage = nil
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTag(_ tag: String) {
        if let index = selectedTagNames.firstIndex(of: tag) {
            selectedTagNames.remove(at: index)
        } else {
            selectedTagNames.append(tag)
        }
    }

    func presentCreateTag() {
        newTagName = ""
        isCreateTagPresented = true
    }

    func createTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Введите название тега."
            return
        }

        do {
            let normalizedName = TagRepository.normalizedName(for: trimmedName)

            if let existingTag = try tagRepository.fetchByNormalizedName(normalizedName) {
                if selectedTagNames.contains(existingTag.name) == false {
                    selectedTagNames.append(existingTag.name)
                }
            } else {
                let tag = Tag(name: trimmedName)
                try tagRepository.insert(tag)
                selectedTagNames.append(tag.name)
            }

            errorMessage = nil
            newTagName = ""
            isCreateTagPresented = false
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var pauseButtonTitle: String {
        timerService.activeSession?.isPaused == true ? "Продолжить" : "Пауза"
    }

    var pauseButtonIconName: String {
        timerService.activeSession?.isPaused == true ? "play" : "pause"
    }

    private var currentElapsedDuration: TimeInterval {
        guard let activeSession = timerService.activeSession else {
            return 0
        }

        return timerService.elapsedDuration(for: activeSession)
    }

    private var currentResolvedRate: Decimal {
        if let activeSession = timerService.activeSession {
            return activeSession.resolvedHourlyRateSnapshot
        }

        return sessionCalculator.resolvedRate(
            sessionCustomRate: parseOptionalDecimal(customRateText.trimmingCharacters(in: .whitespacesAndNewlines)),
            projectRate: selectedProject?.hourlyRate,
            defaultRate: settings?.defaultHourlyRate ?? .zero
        )
    }

    private var currentTimerIncome: Decimal {
        guard let activeSession = timerService.activeSession else {
            return .zero
        }

        return sessionCalculator.income(
            durationSeconds: currentElapsedDuration,
            hourlyRate: activeSession.resolvedHourlyRateSnapshot
        )
    }

    private func parseOptionalDecimal(_ value: String) -> Decimal? {
        guard value.isEmpty == false else {
            return nil
        }

        return Decimal(string: value.replacingOccurrences(of: ",", with: "."))
    }
}

struct DashboardTagSuggestion: Identifiable {
    static let defaultPalette = ["#4C8BF5", "#FF9F68", "#4FAF92", "#9B7CFF", "#F15D7A", "#F0C15B"]
    static let palette = [
        "Frontend": "#7C5CFF",
        "UI/UX": "#5B7CFA",
        "WordPress": "#5CC47D",
        "Клиент": "#F4D65A"
    ]

    let title: String
    let colorHex: String
    let isSelected: Bool

    var id: String { title }
}

private extension Array where Element: Hashable {
    func orderedUnique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
