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
    private let reportService: ReportService
    private let appEnvironment: AppEnvironment
    private(set) var projects: [Project] = []
    private(set) var recentSessions: [WorkSession] = []
    private(set) var settings: AppSettings?
    private(set) var todaySummary: DaySummaryReport?
    private(set) var yesterdaySummary: DaySummaryReport?
    var selectedProjectID: UUID?
    var sessionNote = ""
    var tagsText = ""
    var customRateText = ""
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.sessionCalculator = appEnvironment.sessionCalculator
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.dayNoteRepository = appEnvironment.dayNoteRepository
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

    var activeTimerDurationText: String {
        AppFormatters.durationText(from: currentElapsedDuration)
    }

    var activeTimerIncomeText: String {
        AppFormatters.currencyText(currentTimerIncome, currencyCode: currencyCode)
    }

    var suggestedTags: [DashboardTagSuggestion] {
        let defaultTags = ["Frontend", "UI/UX", "WordPress", "Клиент"]
        let recentTags = Array(Set(recentSessions.flatMap(\.tags))).sorted()
        let tags = (recentTags + defaultTags).orderedUnique()
        let activeTags = Set(parsedTags())

        return tags.prefix(6).enumerated().map { index, tag in
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

            if selectedProjectID == nil {
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
                tags: parsedTags(),
                customHourlyRate: customRate
            )

            sessionNote = ""
            tagsText = ""
            customRateText = ""
            errorMessage = nil
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopTimer() {
        do {
            try timerService.stopActiveTimer()
            errorMessage = nil
            reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pauseTimer() {
        errorMessage = "Пауза появится в следующем обновлении таймера."
    }

    func toggleTag(_ tag: String) {
        var tags = parsedTags()

        if let index = tags.firstIndex(of: tag) {
            tags.remove(at: index)
        } else {
            tags.append(tag)
        }

        tagsText = tags.joined(separator: ", ")
    }

    private var currentElapsedDuration: TimeInterval {
        guard let activeSession = timerService.activeSession else {
            return 0
        }

        return max(0, timerService.currentDate.timeIntervalSince(activeSession.startTime))
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

    private func parsedTags() -> [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}

struct DashboardTagSuggestion: Identifiable {
    static let defaultPalette = ["#4C8BF5", "#FF9F68", "#4FAF92", "#9B7CFF", "#F15D7A", "#F0C15B"]
    static let palette = [
        "Frontend": "#4C8BF5",
        "UI/UX": "#9B7CFF",
        "WordPress": "#4FAF92",
        "Клиент": "#FF9F68"
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
