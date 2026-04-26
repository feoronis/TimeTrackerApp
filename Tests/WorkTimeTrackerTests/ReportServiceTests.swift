import Foundation
import Testing
@testable import WorkTimeTracker

struct ReportServiceTests {
    private let sessionCalculator = SessionCalculator()
    private var reportService: ReportService {
        ReportService(sessionCalculator: sessionCalculator)
    }

    @Test
    func daySummaryGroupsSessionsByProjectAndSumsIncomePerSession() {
        let day = Date(timeIntervalSince1970: 1_000_000)
        let project = Project(name: "Проект A")
        let sessionOne = WorkSession(
            project: project,
            startTime: day,
            endTime: day.addingTimeInterval(3600),
            durationSeconds: 3600,
            resolvedHourlyRateSnapshot: Decimal(100)
        )
        let sessionTwo = WorkSession(
            project: project,
            startTime: day.addingTimeInterval(7200),
            endTime: day.addingTimeInterval(9000),
            durationSeconds: 1800,
            resolvedHourlyRateSnapshot: Decimal(200)
        )

        let summary = reportService.buildDaySummary(
            sessions: [sessionOne, sessionTwo],
            selectedDate: day,
            dayNote: nil
        )

        #expect(summary.sessionCount == 2)
        #expect(summary.projectCount == 1)
        #expect(summary.totalDurationSeconds == 5400)
        #expect(summary.totalIncome == Decimal(200))
        #expect(summary.projectRows.first?.income == Decimal(200))
    }

    @Test
    func periodReportRespectsProjectAndTagFilters() {
        let baseDate = Date(timeIntervalSince1970: 2_000_000)
        let projectA = Project(name: "Проект A")
        let projectB = Project(name: "Проект B")
        let targetSession = WorkSession(
            project: projectA,
            startTime: baseDate,
            endTime: baseDate.addingTimeInterval(3600),
            durationSeconds: 3600,
            note: "Важная задача",
            tags: ["ios"],
            resolvedHourlyRateSnapshot: Decimal(150)
        )
        let otherSession = WorkSession(
            project: projectB,
            startTime: baseDate,
            endTime: baseDate.addingTimeInterval(1800),
            durationSeconds: 1800,
            tags: ["backend"],
            resolvedHourlyRateSnapshot: Decimal(90)
        )

        let filter = ReportFilter(
            period: .custom,
            customStartDate: baseDate,
            customEndDate: baseDate,
            projectID: projectA.id,
            tag: "ios"
        )

        let report = reportService.buildPeriodReport(
            sessions: [targetSession, otherSession],
            filter: filter
        )

        #expect(report.summary.sessionCount == 1)
        #expect(report.projectRows.count == 1)
        #expect(report.projectRows.first?.projectName == "Проект A")
        #expect(report.summary.totalIncome == Decimal(150))
    }

    @Test
    func todayReportBuildsHourlySeries() {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let project = Project(name: "Проект A")
        let session = WorkSession(
            project: project,
            startTime: startOfDay.addingTimeInterval(2 * 3600),
            endTime: startOfDay.addingTimeInterval(3 * 3600),
            durationSeconds: 3600,
            resolvedHourlyRateSnapshot: Decimal(100)
        )

        let report = reportService.buildPeriodReport(
            sessions: [session],
            filter: ReportFilter(period: .custom, customStartDate: startOfDay, customEndDate: startOfDay),
            calendar: calendar
        )

        #expect(report.chartGranularity == .hour)
        #expect(report.timeByDate.count == 24)
        #expect(report.timeByDate.contains { $0.date == startOfDay.addingTimeInterval(2 * 3600) && $0.totalDurationSeconds == 3600 })
    }
}
