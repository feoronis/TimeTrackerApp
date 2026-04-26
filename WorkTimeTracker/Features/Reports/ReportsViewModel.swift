import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class ReportsViewModel {
    private let reportService: ReportService
    private let sessionRepository: SessionRepository
    private let projectRepository: ProjectRepository
    private let settingsRepository: SettingsRepository
    private let appEnvironment: AppEnvironment

    private(set) var settings: AppSettings?
    private(set) var projects: [Project] = []
    private(set) var report: PeriodReport?
    private(set) var previousReport: PeriodReport?
    var filter: ReportFilter
    var expandedProjectIDs = Set<String>()
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.reportService = appEnvironment.reportService
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.appEnvironment = appEnvironment
        self.filter = ReportFilter(
            period: .thisMonth,
            customStartDate: .now,
            customEndDate: .now
        )
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var periodButtons: [ReportsPeriodOption] {
        [
            .init(title: "Сегодня", period: .today),
            .init(title: "Неделя", period: .thisWeek),
            .init(title: "Месяц", period: .thisMonth),
            .init(title: "Свой период", period: .custom)
        ]
    }

    var selectedPeriodTitle: String {
        switch filter.period {
        case .today:
            return "Сегодня"
        case .thisWeek:
            return "Неделя"
        case .thisMonth:
            return "Месяц"
        case .custom:
            return "Свой период"
        default:
            return filter.period.title
        }
    }

    var rangeText: String {
        let interval = report.map { reportService.dateInterval(for: $0.filter) } ?? reportService.dateInterval(for: filter)
        return "\(AppFormatters.reportShortDateText(interval.start)) - \(AppFormatters.reportShortDateText(interval.end.addingTimeInterval(-1)))"
    }

    var summaryCards: [ReportsSummaryCardItem] {
        let summary = report?.summary
        let previous = previousReport?.summary
        let currentTopProjectIncome = report?.projectRows.max(by: { $0.income < $1.income })?.income ?? .zero
        let previousTopProjectIncome = previousReport?.projectRows.max(by: { $0.income < $1.income })?.income ?? .zero

        return [
            ReportsSummaryCardItem(
                title: "Общее время",
                value: AppFormatters.compactDurationText(from: summary?.totalDurationSeconds ?? 0),
                subtitle: durationTrend(
                    current: summary?.totalDurationSeconds ?? 0,
                    previous: previous?.totalDurationSeconds ?? 0
                ),
                trendDirection: timeTrendDirection(
                    current: summary?.totalDurationSeconds ?? 0,
                    previous: previous?.totalDurationSeconds ?? 0
                ),
                iconAssetName: "ReportTime"
            ),
            ReportsSummaryCardItem(
                title: "Общий доход",
                value: AppFormatters.currencyText(summary?.totalIncome ?? .zero, currencyCode: currencyCode),
                subtitle: currencyTrend(
                    current: summary?.totalIncome ?? .zero,
                    previous: previous?.totalIncome ?? .zero
                ),
                trendDirection: decimalTrendDirection(
                    current: summary?.totalIncome ?? .zero,
                    previous: previous?.totalIncome ?? .zero
                ),
                iconAssetName: "ReportRuble"
            ),
            ReportsSummaryCardItem(
                title: "Рабочие дни",
                value: "\(summary?.workDaysCount ?? 0)",
                subtitle: integerTrend(
                    current: summary?.workDaysCount ?? 0,
                    previous: previous?.workDaysCount ?? 0
                ),
                trendDirection: integerTrendDirection(
                    current: summary?.workDaysCount ?? 0,
                    previous: previous?.workDaysCount ?? 0
                ),
                iconAssetName: "ReportCalendar"
            ),
            ReportsSummaryCardItem(
                title: "Средний доход / день",
                value: AppFormatters.currencyText(summary?.averageIncomePerWorkDay ?? .zero, currencyCode: currencyCode),
                subtitle: currencyTrend(
                    current: summary?.averageIncomePerWorkDay ?? .zero,
                    previous: previous?.averageIncomePerWorkDay ?? .zero
                ),
                trendDirection: decimalTrendDirection(
                    current: summary?.averageIncomePerWorkDay ?? .zero,
                    previous: previous?.averageIncomePerWorkDay ?? .zero
                ),
                iconAssetName: "ReportLine"
            ),
            ReportsSummaryCardItem(
                title: "Самый прибыльный",
                value: summary?.mostProfitableProjectName ?? "Нет данных",
                subtitle: currencyTrend(
                    current: currentTopProjectIncome,
                    previous: previousTopProjectIncome
                ),
                trendDirection: decimalTrendDirection(
                    current: currentTopProjectIncome,
                    previous: previousTopProjectIncome
                ),
                iconAssetName: "ReportFire"
            )
        ]
    }

    func load() {
        appEnvironment.bootstrap()
        reload()
    }

    func reload() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            let sessions = try sessionRepository.fetchAll()
            report = reportService.buildPeriodReport(sessions: sessions, filter: filter)
            previousReport = reportService.buildPeriodReport(sessions: sessions, filter: previousFilter(for: filter))
            errorMessage = appEnvironment.bootstrapErrorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setPeriod(_ period: ReportPeriod) {
        filter.period = period

        if period != .custom {
            let interval = reportService.dateInterval(for: filter)
            filter.customStartDate = interval.start
            filter.customEndDate = interval.end.addingTimeInterval(-1)
        }

        applyFilters()
    }

    func applyFilters() {
        expandedProjectIDs.removeAll()
        reload()
    }

    private func durationTrend(current: TimeInterval, previous: TimeInterval) -> String {
        AppFormatters.comparisonDurationText(current - previous)
    }

    private func currencyTrend(current: Decimal, previous: Decimal) -> String {
        AppFormatters.comparisonCurrencyText(current - previous, currencyCode: currencyCode)
    }

    private func integerTrend(current: Int, previous: Int) -> String {
        let delta = current - previous
        let prefix = delta >= 0 ? "+" : "−"
        return "\(prefix)\(abs(delta)) \(workDayNoun(for: abs(delta)))"
    }

    private func workDayNoun(for count: Int) -> String {
        let normalized = count % 100
        if normalized >= 11 && normalized <= 14 {
            return "дней"
        }

        switch count % 10 {
        case 1:
            return "день"
        case 2, 3, 4:
            return "дня"
        default:
            return "дней"
        }
    }

    private func timeTrendDirection(current: TimeInterval, previous: TimeInterval) -> ReportsTrendDirection {
        trendDirection(current: current, previous: previous)
    }

    private func decimalTrendDirection(current: Decimal, previous: Decimal) -> ReportsTrendDirection {
        trendDirection(
            current: NSDecimalNumber(decimal: current).doubleValue,
            previous: NSDecimalNumber(decimal: previous).doubleValue
        )
    }

    private func integerTrendDirection(current: Int, previous: Int) -> ReportsTrendDirection {
        trendDirection(current: Double(current), previous: Double(previous))
    }

    private func trendDirection(current: Double, previous: Double) -> ReportsTrendDirection {
        if current > previous { return .up }
        if current < previous { return .down }
        return .neutral
    }

    private func previousFilter(for filter: ReportFilter) -> ReportFilter {
        let calendar = Calendar.current
        let currentInterval = reportService.dateInterval(for: filter, calendar: calendar)
        switch filter.period {
        case .today:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: currentInterval.start) ?? currentInterval.start
            return ReportFilter(period: .custom, customStartDate: yesterday, customEndDate: yesterday)
        case .thisWeek:
            let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentInterval.start) ?? currentInterval.start
            let previousEnd = calendar.date(byAdding: .second, value: -1, to: currentInterval.start) ?? previousStart
            return ReportFilter(period: .custom, customStartDate: previousStart, customEndDate: previousEnd)
        case .thisMonth:
            let previousStart = calendar.date(byAdding: .month, value: -1, to: currentInterval.start) ?? currentInterval.start
            let previousEnd = calendar.date(byAdding: .second, value: -1, to: currentInterval.start) ?? previousStart
            return ReportFilter(period: .custom, customStartDate: previousStart, customEndDate: previousEnd)
        case .custom:
            let previousEnd = calendar.date(byAdding: .second, value: -1, to: currentInterval.start) ?? currentInterval.start
            let previousStart = previousEnd.addingTimeInterval(-currentInterval.duration + 1)
            return ReportFilter(period: .custom, customStartDate: previousStart, customEndDate: previousEnd)
        default:
            return ReportFilter(period: .lastMonth, customStartDate: .now, customEndDate: .now)
        }
    }
}

struct ReportsPeriodOption: Identifiable {
    let title: String
    let period: ReportPeriod

    var id: String { title }
}

struct ReportsSummaryCardItem: Identifiable {
    let title: String
    let value: String
    let subtitle: String
    let trendDirection: ReportsTrendDirection
    let iconAssetName: String

    var id: String { title }
}

enum ReportsTrendDirection: Equatable {
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

    var color: Color {
        switch self {
        case .up:
            return Color(hex: "#31A85B")!
        case .down:
            return Color(hex: "#FB4E42")!
        case .neutral:
            return Color(hex: "#94A3B8")!
        }
    }
}
