import Foundation

enum ReportPeriod: Equatable, CaseIterable, Identifiable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case custom

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .today:
            return "Сегодня"
        case .yesterday:
            return "Вчера"
        case .thisWeek:
            return "Эта неделя"
        case .lastWeek:
            return "Прошлая неделя"
        case .thisMonth:
            return "Этот месяц"
        case .lastMonth:
            return "Прошлый месяц"
        case .custom:
            return "Произвольный период"
        }
    }

    static var allCases: [ReportPeriod] {
        [.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .lastMonth, .custom]
    }
}

struct ReportFilter {
    var period: ReportPeriod
    var customStartDate: Date
    var customEndDate: Date
    var projectID: UUID?
    var tag: String?

    init(
        period: ReportPeriod = .thisWeek,
        customStartDate: Date = .now,
        customEndDate: Date = .now,
        projectID: UUID? = nil,
        tag: String? = nil
    ) {
        self.period = period
        self.customStartDate = customStartDate
        self.customEndDate = customEndDate
        self.projectID = projectID
        self.tag = tag
    }
}

struct SessionReportRow: Identifiable {
    let id: UUID
    let projectName: String
    let startTime: Date
    let endTime: Date?
    let note: String?
    let tags: [String]
    let hourlyRate: Decimal
    let durationSeconds: TimeInterval
    let income: Decimal
}

struct ProjectReportRow: Identifiable {
    let id: String
    let projectID: UUID?
    let projectName: String
    let totalDurationSeconds: TimeInterval
    let sessionCount: Int
    let averageInformationalRate: Decimal
    let income: Decimal
    let sessions: [SessionReportRow]
}

struct DailyChartPoint: Identifiable {
    let date: Date
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal

    var id: Date { date }
}

struct ProjectChartPoint: Identifiable {
    let projectName: String
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal

    var id: String { projectName }
}

struct DaySummaryReport {
    let date: Date
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal
    let sessionCount: Int
    let projectCount: Int
    let mostActiveProjectName: String?
    let projectRows: [ProjectReportRow]
    let dayNote: DayNote?
}

struct PeriodReportSummary {
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal
    let workDaysCount: Int
    let sessionCount: Int
    let averageDurationPerWorkDay: TimeInterval
    let averageIncomePerWorkDay: Decimal
    let mostProfitableProjectName: String?
    let longestProjectName: String?
}

struct PeriodReport {
    let filter: ReportFilter
    let summary: PeriodReportSummary
    let projectRows: [ProjectReportRow]
    let incomeByDay: [DailyChartPoint]
    let timeByDay: [DailyChartPoint]
    let timeByProject: [ProjectChartPoint]
    let incomeByProject: [ProjectChartPoint]
    let availableTags: [String]
}

struct ReportService {
    private let sessionCalculator: SessionCalculator

    init(sessionCalculator: SessionCalculator) {
        self.sessionCalculator = sessionCalculator
    }

    func buildDaySummary(
        sessions: [WorkSession],
        selectedDate: Date,
        dayNote: DayNote?,
        calendar: Calendar = .current
    ) -> DaySummaryReport {
        let daySessions = sessions
            .filter { session in
                calendar.isDate(session.startTime, inSameDayAs: selectedDate)
            }
            .sorted { $0.startTime > $1.startTime }

        let projectRows = buildProjectRows(from: daySessions)
        let totalDuration = daySessions.reduce(0) { $0 + $1.durationSeconds }
        let totalIncome = daySessions.reduce(Decimal.zero) { partialResult, session in
            partialResult + sessionCalculator.sessionIncome(session)
        }
        let projectIdentifiers = Set(
            daySessions.map { session in
                session.project.map { $0.id.uuidString } ?? "Без проекта"
            }
        )

        return DaySummaryReport(
            date: calendar.startOfDay(for: selectedDate),
            totalDurationSeconds: totalDuration,
            totalIncome: totalIncome,
            sessionCount: daySessions.count,
            projectCount: projectIdentifiers.count,
            mostActiveProjectName: projectRows.first?.projectName,
            projectRows: projectRows,
            dayNote: dayNote
        )
    }

    func buildPeriodReport(
        sessions: [WorkSession],
        filter: ReportFilter,
        calendar: Calendar = .current
    ) -> PeriodReport {
        let interval = dateInterval(for: filter, calendar: calendar)
        let filteredSessions = sessions
            .filter { session in
                interval.contains(session.startTime)
            }
            .filter { session in
                guard let projectID = filter.projectID else { return true }
                return session.project?.id == projectID
            }
            .filter { session in
                guard let tag = filter.tag, tag.isEmpty == false else { return true }
                return session.tags.contains(tag)
            }
            .sorted { $0.startTime > $1.startTime }

        let projectRows = buildProjectRows(from: filteredSessions)
        let summary = buildSummary(
            sessions: filteredSessions,
            projectRows: projectRows,
            calendar: calendar
        )

        let dailyPoints = buildDailyPoints(from: filteredSessions, calendar: calendar)
        let projectPoints = buildProjectPoints(from: projectRows)
        let availableTags = Array(Set(sessions.flatMap(\.tags))).sorted()

        return PeriodReport(
            filter: filter,
            summary: summary,
            projectRows: projectRows,
            incomeByDay: dailyPoints,
            timeByDay: dailyPoints,
            timeByProject: projectPoints,
            incomeByProject: projectPoints,
            availableTags: availableTags
        )
    }

    func dateInterval(
        for filter: ReportFilter,
        calendar: Calendar = .current
    ) -> DateInterval {
        let now = Date.now

        switch filter.period {
        case .today:
            return dayInterval(for: now, calendar: calendar)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            return dayInterval(for: yesterday, calendar: calendar)
        case .thisWeek:
            return weekInterval(for: now, calendar: calendar)
        case .lastWeek:
            let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return weekInterval(for: lastWeekDate, calendar: calendar)
        case .thisMonth:
            return monthInterval(for: now, calendar: calendar)
        case .lastMonth:
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return monthInterval(for: lastMonthDate, calendar: calendar)
        case .custom:
            let startDate = calendar.startOfDay(for: min(filter.customStartDate, filter.customEndDate))
            let endDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: max(filter.customStartDate, filter.customEndDate))
            ) ?? filter.customEndDate

            return DateInterval(start: startDate, end: endDate)
        }
    }

    private func buildSummary(
        sessions: [WorkSession],
        projectRows: [ProjectReportRow],
        calendar: Calendar
    ) -> PeriodReportSummary {
        let totalDuration = sessions.reduce(0) { $0 + $1.durationSeconds }
        let totalIncome = sessions.reduce(Decimal.zero) { partialResult, session in
            partialResult + sessionCalculator.sessionIncome(session)
        }
        let workDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).count
        let averageDuration = workDays > 0 ? totalDuration / Double(workDays) : 0
        let averageIncome = workDays > 0 ? totalIncome / Decimal(workDays) : .zero

        return PeriodReportSummary(
            totalDurationSeconds: totalDuration,
            totalIncome: totalIncome,
            workDaysCount: workDays,
            sessionCount: sessions.count,
            averageDurationPerWorkDay: averageDuration,
            averageIncomePerWorkDay: averageIncome,
            mostProfitableProjectName: projectRows.max(by: { $0.income < $1.income })?.projectName,
            longestProjectName: projectRows.max(by: { $0.totalDurationSeconds < $1.totalDurationSeconds })?.projectName
        )
    }

    private func buildProjectRows(from sessions: [WorkSession]) -> [ProjectReportRow] {
        let groupedSessions = Dictionary(
            grouping: sessions,
            by: { session in
                ProjectGroupingKey(
                    projectID: session.project?.id,
                    projectName: session.project?.name ?? "Без проекта"
                )
            }
        )

        return groupedSessions
            .map { key, groupedSessions in
                let reportRows = groupedSessions
                    .sorted { $0.startTime > $1.startTime }
                    .map { session in
                        SessionReportRow(
                            id: session.id,
                            projectName: key.projectName,
                            startTime: session.startTime,
                            endTime: session.endTime,
                            note: session.note,
                            tags: session.tags,
                            hourlyRate: session.resolvedHourlyRateSnapshot,
                            durationSeconds: session.durationSeconds,
                            income: sessionCalculator.sessionIncome(session)
                        )
                    }

                let totalDuration = reportRows.reduce(0) { $0 + $1.durationSeconds }
                let income = reportRows.reduce(Decimal.zero) { $0 + $1.income }
                let averageRate = reportRows.isEmpty
                    ? Decimal.zero
                    : reportRows.reduce(Decimal.zero) { $0 + $1.hourlyRate } / Decimal(reportRows.count)

                return ProjectReportRow(
                    id: key.id,
                    projectID: key.projectID,
                    projectName: key.projectName,
                    totalDurationSeconds: totalDuration,
                    sessionCount: reportRows.count,
                    averageInformationalRate: averageRate,
                    income: income,
                    sessions: reportRows
                )
            }
            .sorted { lhs, rhs in
                if lhs.totalDurationSeconds == rhs.totalDurationSeconds {
                    return lhs.projectName < rhs.projectName
                }

                return lhs.totalDurationSeconds > rhs.totalDurationSeconds
            }
    }

    private func buildDailyPoints(
        from sessions: [WorkSession],
        calendar: Calendar
    ) -> [DailyChartPoint] {
        let groupedSessions = Dictionary(
            grouping: sessions,
            by: { calendar.startOfDay(for: $0.startTime) }
        )

        return groupedSessions
            .map { date, daySessions in
                DailyChartPoint(
                    date: date,
                    totalDurationSeconds: daySessions.reduce(0) { $0 + $1.durationSeconds },
                    totalIncome: daySessions.reduce(Decimal.zero) { $0 + sessionCalculator.sessionIncome($1) }
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func buildProjectPoints(from projectRows: [ProjectReportRow]) -> [ProjectChartPoint] {
        projectRows.map { row in
            ProjectChartPoint(
                projectName: row.projectName,
                totalDurationSeconds: row.totalDurationSeconds,
                totalIncome: row.income
            )
        }
    }

    private func dayInterval(for date: Date, calendar: Calendar) -> DateInterval {
        let startDate = calendar.startOfDay(for: date)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) ?? date
        return DateInterval(start: startDate, end: endDate)
    }

    private func weekInterval(for date: Date, calendar: Calendar) -> DateInterval {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date)
        return interval ?? dayInterval(for: date, calendar: calendar)
    }

    private func monthInterval(for date: Date, calendar: Calendar) -> DateInterval {
        let interval = calendar.dateInterval(of: .month, for: date)
        return interval ?? dayInterval(for: date, calendar: calendar)
    }
}

private struct ProjectGroupingKey: Hashable {
    let projectID: UUID?
    let projectName: String

    var id: String {
        projectID?.uuidString ?? "no-project-\(projectName)"
    }
}
