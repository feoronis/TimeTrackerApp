import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class SessionsViewModel {
    private let sessionRepository: SessionRepository
    private let projectRepository: ProjectRepository
    private let settingsRepository: SettingsRepository
    private let tagRepository: TagRepository
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

    var selectedProjectID: UUID?
    var selectedTag: String?
    var currentPage = 1
    var pageSize = 10
    var dateSelectionMode: SessionsDateSelectionMode = .month
    var displayedMonth: Date
    var startDate: Date
    var endDate: Date

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.tagRepository = appEnvironment.tagRepository
        self.sessionCalculator = appEnvironment.sessionCalculator
        let monthInterval = Calendar.current.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, duration: 86400)
        self.displayedMonth = monthInterval.start
        self.startDate = monthInterval.start
        self.endDate = monthInterval.end.addingTimeInterval(-1)
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var availableTags: [String] {
        Array(Set(sessions.flatMap(\.tags))).sorted()
    }

    var filteredSessions: [WorkSession] {
        let interval = normalizedDateInterval

        return sessions
            .filter { session in
                session.startTime >= interval.start
                && session.startTime < interval.end
            }
            .filter(matchesSelectedFilters)
            .sorted { lhs, rhs in
                let lhsDate = lhs.endTime ?? lhs.startTime
                let rhsDate = rhs.endTime ?? rhs.startTime

                if lhsDate == rhsDate {
                    return lhs.startTime > rhs.startTime
                }

                return lhsDate > rhsDate
            }
    }

    var pagedSessions: [WorkSession] {
        let startIndex = max(0, (currentPage - 1) * pageSize)
        let endIndex = min(filteredSessions.count, startIndex + pageSize)
        guard startIndex < endIndex else { return [] }
        return Array(filteredSessions[startIndex..<endIndex])
    }

    var totalPages: Int {
        max(1, Int(ceil(Double(filteredSessions.count) / Double(pageSize))))
    }

    var pageDescription: String {
        guard filteredSessions.isEmpty == false else {
            return "Показано 0 из 0 сессий"
        }

        let start = (currentPage - 1) * pageSize + 1
        let end = min(filteredSessions.count, currentPage * pageSize)
        return "Показано \(start)–\(end) из \(filteredSessions.count) сессий"
    }

    var rangeText: String {
        "\(AppFormatters.reportShortDateText(startDate)) - \(AppFormatters.reportShortDateText(endDate))"
    }

    var monthTitle: String {
        AppFormatters.monthYearText(displayedMonth)
    }

    var monthOptions: [SessionsMonthOption] {
        let calendar = Calendar.current
        let month = monthStart(for: displayedMonth)

        return (-6...6)
            .compactMap { offset -> SessionsMonthOption? in
                guard let date = calendar.date(byAdding: .month, value: offset, to: month) else {
                    return nil
                }

                return SessionsMonthOption(date: date, title: AppFormatters.monthYearText(date))
            }
            .reversed()
    }

    var summaryCards: [SessionSummaryCardItem] {
        let current = filteredSessions
        let previous = previousPeriodSessions

        let currentDuration = current.reduce(0) { $0 + $1.durationSeconds }
        let previousDuration = previous.reduce(0) { $0 + $1.durationSeconds }
        let currentIncome = current.reduce(Decimal.zero) { $0 + sessionCalculator.sessionIncome($1) }
        let previousIncome = previous.reduce(Decimal.zero) { $0 + sessionCalculator.sessionIncome($1) }
        let currentAverageRate = current.isEmpty ? .zero : current.reduce(Decimal.zero) { $0 + $1.resolvedHourlyRateSnapshot } / Decimal(current.count)
        let previousAverageRate = previous.isEmpty ? .zero : previous.reduce(Decimal.zero) { $0 + $1.resolvedHourlyRateSnapshot } / Decimal(previous.count)

        return [
            SessionSummaryCardItem(
                title: "Общее время",
                value: AppFormatters.compactDurationText(from: currentDuration),
                subtitle: AppFormatters.comparisonDurationText(currentDuration - previousDuration),
                trendDirection: timeTrendDirection(current: currentDuration, previous: previousDuration),
                iconAssetName: "ReportTime",
                accentColor: Color(hex: "#6B58D6")!,
                backgroundColor: summaryBackground(baseDarkHex: "#22183F", lightHex: "#D7D1FC"),
                borderColor: summaryBorder(baseDarkHex: "#4B3694", lightHex: "#B9AFF7")
            ),
            SessionSummaryCardItem(
                title: "Общий доход",
                value: AppFormatters.currencyText(currentIncome, currencyCode: currencyCode),
                subtitle: AppFormatters.comparisonCurrencyText(currentIncome - previousIncome, currencyCode: currencyCode),
                trendDirection: decimalTrendDirection(current: currentIncome, previous: previousIncome),
                iconAssetName: "ReportRuble",
                accentColor: Color(hex: "#2A8AA1")!,
                backgroundColor: summaryBackground(baseDarkHex: "#102B35", lightHex: "#EFF7F9"),
                borderColor: summaryBorder(baseDarkHex: "#1F5C6D", lightHex: "#CDE8EE")
            ),
            SessionSummaryCardItem(
                title: "Сессий",
                value: "\(current.count)",
                subtitle: sessionCountTrend(current: current.count, previous: previous.count),
                trendDirection: integerTrendDirection(current: current.count, previous: previous.count),
                iconAssetName: "ReportLine",
                accentColor: Color(hex: "#4A74E6")!,
                backgroundColor: summaryBackground(baseDarkHex: "#15274A", lightHex: "#EAF2FE"),
                borderColor: summaryBorder(baseDarkHex: "#3358B8", lightHex: "#C8D9FB")
            ),
            SessionSummaryCardItem(
                title: "Средняя ставка",
                value: AppFormatters.currencyText(currentAverageRate, currencyCode: currencyCode) + "/ч",
                subtitle: AppFormatters.comparisonCurrencyText(currentAverageRate - previousAverageRate, currencyCode: currencyCode),
                trendDirection: decimalTrendDirection(current: currentAverageRate, previous: previousAverageRate),
                iconAssetName: "ReportFire",
                accentColor: Color(hex: "#D6854A")!,
                backgroundColor: summaryBackground(baseDarkHex: "#362114", lightHex: "#FEF5F0"),
                borderColor: summaryBorder(baseDarkHex: "#8C562E", lightHex: "#F6D8C7")
            )
        ]
    }

    private func summaryBackground(baseDarkHex: String, lightHex: String) -> Color {
        if AppearancePreferences.isDarkMode {
            return (Color(hex: baseDarkHex) ?? AppColors.cardSecondaryFill).opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.92 : 0.98)
        }

        return Color(hex: lightHex) ?? AppColors.cardSecondaryFill
    }

    private func summaryBorder(baseDarkHex: String, lightHex: String) -> Color {
        if AppearancePreferences.isDarkMode {
            return (Color(hex: baseDarkHex) ?? AppColors.tableBorder).opacity(0.95)
        }

        return Color(hex: lightHex) ?? AppColors.tableBorder
    }

    func load() {
        appEnvironment.bootstrap()

        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            sessions = try sessionRepository.fetchAll()
            currentPage = min(currentPage, totalPages)
            errorMessage = appEnvironment.bootstrapErrorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetFilters() {
        selectedProjectID = nil
        selectedTag = nil
        dateSelectionMode = .month
        let interval = Calendar.current.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, duration: 86400)
        displayedMonth = interval.start
        startDate = interval.start
        endDate = interval.end.addingTimeInterval(-1)
        currentPage = 1
    }

    func selectPage(_ page: Int) {
        currentPage = min(max(1, page), totalPages)
    }

    func activateMonthMode() {
        dateSelectionMode = .month
        applyMonth(displayedMonth)
    }

    func activateCustomMode() {
        dateSelectionMode = .custom
        currentPage = 1
    }

    func selectPreviousMonth() {
        let calendar = Calendar.current
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: monthStart(for: displayedMonth)) ?? displayedMonth
        activateMonthMode()
    }

    func selectNextMonth() {
        let calendar = Calendar.current
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: monthStart(for: displayedMonth)) ?? displayedMonth
        activateMonthMode()
    }

    func selectMonth(_ date: Date) {
        displayedMonth = monthStart(for: date)
        activateMonthMode()
    }

    func updateCustomStartDate(_ date: Date) {
        dateSelectionMode = .custom
        startDate = date
        currentPage = 1
    }

    func updateCustomEndDate(_ date: Date) {
        dateSelectionMode = .custom
        endDate = date
        currentPage = 1
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
            appEnvironment.notifyDataChanged()
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
        let parsedDraftTags = parsedTags(draft.tagsText)
        let fixedIncomeAmount = parseOptionalDecimal(draft.fixedIncomeAmountText.trimmingCharacters(in: .whitespacesAndNewlines))
        let normalizedDates = normalizedDates(for: draft)

        guard draft.fixedIncomeAmountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || fixedIncomeAmount != nil else {
            errorMessage = "Фиксированная сумма должна быть числом."
            return
        }

        guard normalizedDates.end >= normalizedDates.start else {
            errorMessage = "Окончание не может быть раньше начала."
            return
        }

        let calculatedValues = sessionCalculator.calculateCompletedSessionValues(
            start: normalizedDates.start,
            end: normalizedDates.end,
            sessionCustomRate: customRate,
            projectRate: selectedProject?.hourlyRate,
            defaultRate: settings.defaultHourlyRate,
            roundingMode: SessionCalculator.RoundingMode(rawValue: settings.roundingMode) ?? .none,
            roundingMinutes: settings.roundingMinutes,
            fixedIncomeAmount: fixedIncomeAmount
        )

        do {
            if let editingSession {
                editingSession.project = selectedProject
                editingSession.startTime = normalizedDates.start
                editingSession.endTime = normalizedDates.end
                editingSession.durationSeconds = calculatedValues.durationSeconds
                editingSession.note = sanitizedText(draft.note)
                editingSession.tags = parsedDraftTags
                editingSession.customHourlyRate = customRate
                editingSession.resolvedHourlyRateSnapshot = calculatedValues.resolvedHourlyRateSnapshot
                editingSession.fixedIncomeAmount = fixedIncomeAmount
                editingSession.pausedAt = nil
                editingSession.accumulatedPausedSeconds = 0
                editingSession.updatedAt = .now
                try tagRepository.upsertMissingTags(named: parsedDraftTags)
                try sessionRepository.save()
            } else {
                let session = WorkSession(
                    project: selectedProject,
                    startTime: normalizedDates.start,
                    endTime: normalizedDates.end,
                    durationSeconds: calculatedValues.durationSeconds,
                    note: sanitizedText(draft.note),
                    tags: parsedDraftTags,
                    customHourlyRate: customRate,
                    resolvedHourlyRateSnapshot: calculatedValues.resolvedHourlyRateSnapshot,
                    fixedIncomeAmount: fixedIncomeAmount
                )
                try tagRepository.upsertMissingTags(named: parsedDraftTags)
                try sessionRepository.insert(session)
            }

            isEditorPresented = false
            errorMessage = nil
            appEnvironment.notifyDataChanged()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func incomeText(for session: WorkSession) -> String {
        AppFormatters.currencyText(sessionCalculator.sessionIncome(session), currencyCode: currencyCode)
    }

    func rateText(for session: WorkSession) -> String {
        if session.usesFixedIncomeAmount {
            return "Фикс."
        }

        return AppFormatters.currencyText(session.resolvedHourlyRateSnapshot, currencyCode: currencyCode) + "/ч"
    }

    private var previousPeriodSessions: [WorkSession] {
        let interval = normalizedDateInterval
        let previousStart = interval.start.addingTimeInterval(-interval.duration)
        let previousEnd = interval.start

        return sessions.filter { session in
            session.startTime >= previousStart
            && session.startTime < previousEnd
            && matchesSelectedFilters(session)
        }
    }

    private var normalizedDateInterval: DateInterval {
        let calendar = Calendar.current
        let lowerBound = min(startDate, endDate)
        let upperBound = max(startDate, endDate)
        let start = calendar.startOfDay(for: lowerBound)
        let endDay = calendar.startOfDay(for: upperBound)
        let exclusiveEnd = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay.addingTimeInterval(86_400)

        return DateInterval(start: start, end: max(exclusiveEnd, start.addingTimeInterval(86_400)))
    }

    private func matchesSelectedFilters(_ session: WorkSession) -> Bool {
        if let selectedProjectID, session.project?.id != selectedProjectID {
            return false
        }

        if let selectedTag, selectedTag.isEmpty == false, session.tags.contains(selectedTag) == false {
            return false
        }

        return true
    }

    private func applyMonth(_ date: Date) {
        let interval = Calendar.current.dateInterval(of: .month, for: monthStart(for: date)) ?? DateInterval(start: date, duration: 86_400)
        startDate = interval.start
        endDate = interval.end.addingTimeInterval(-1)
        currentPage = 1
    }

    private func monthStart(for date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }

    private func sessionCountTrend(current: Int, previous: Int) -> String {
        let delta = current - previous
        let prefix = delta >= 0 ? "+" : "−"
        return "\(prefix)\(abs(delta)) \(sessionNoun(for: abs(delta)))"
    }

    private func sessionNoun(for count: Int) -> String {
        let normalized = count % 100
        if normalized >= 11 && normalized <= 14 {
            return "сессий"
        }

        switch count % 10 {
        case 1:
            return "сессия"
        case 2, 3, 4:
            return "сессии"
        default:
            return "сессий"
        }
    }

    private func timeTrendDirection(current: TimeInterval, previous: TimeInterval) -> SessionsTrendDirection {
        trendDirection(current: current, previous: previous)
    }

    private func decimalTrendDirection(current: Decimal, previous: Decimal) -> SessionsTrendDirection {
        trendDirection(
            current: NSDecimalNumber(decimal: current).doubleValue,
            previous: NSDecimalNumber(decimal: previous).doubleValue
        )
    }

    private func integerTrendDirection(current: Int, previous: Int) -> SessionsTrendDirection {
        trendDirection(current: Double(current), previous: Double(previous))
    }

    private func trendDirection(current: Double, previous: Double) -> SessionsTrendDirection {
        if current > previous { return .up }
        if current < previous { return .down }
        return .neutral
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

    private func normalizedDates(for draft: SessionDraft) -> (start: Date, end: Date) {
        switch draft.mode {
        case .timedInterval:
            return (draft.startTime, draft.endTime)
        case .completedTask:
            let totalMinutes = max(0, draft.durationHours * 60 + draft.durationMinutes)
            let end = draft.completedAt
            let start = end.addingTimeInterval(-TimeInterval(totalMinutes * 60))
            return (start, end)
        }
    }

    private func parsedTags(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }
}

struct SessionSummaryCardItem: Identifiable {
    let title: String
    let value: String
    let subtitle: String
    let trendDirection: SessionsTrendDirection
    let iconAssetName: String
    let accentColor: Color
    let backgroundColor: Color
    let borderColor: Color

    var id: String { title }
}

enum SessionsDateSelectionMode {
    case month
    case custom
}

struct SessionsMonthOption: Identifiable {
    let date: Date
    let title: String

    var id: TimeInterval { date.timeIntervalSince1970 }
}

enum SessionsTrendDirection {
    case up
    case down
    case neutral

    var symbolName: String {
        switch self {
        case .up:
            return "arrow.up.forward.circle.fill"
        case .down:
            return "arrow.down.forward.circle.fill"
        case .neutral:
            return "minus.circle.fill"
        }
    }
}
