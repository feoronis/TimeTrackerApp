import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct SessionsViewModelTests {
    @Test
    func customRangeHandlesReversedDatesAndBuildsPreviousPeriodSafely() throws {
        let context = try SessionsTestContext()
        let project = Project(name: "Клиент A")

        try context.environment.projectRepository.insert(project)

        let currentOne = Date(timeIntervalSince1970: 1_705_708_800) // 2024-01-10 12:00 UTC
        let currentTwo = Date(timeIntervalSince1970: 1_705_881_600) // 2024-01-12 12:00 UTC
        let previousOne = Date(timeIntervalSince1970: 1_705_449_600) // 2024-01-07 12:00 UTC
        let previousTwo = Date(timeIntervalSince1970: 1_705_536_000) // 2024-01-08 12:00 UTC

        try context.environment.sessionRepository.insert(
            WorkSession(
                project: project,
                startTime: currentOne,
                endTime: currentOne.addingTimeInterval(3600),
                durationSeconds: 3600,
                resolvedHourlyRateSnapshot: Decimal(100)
            )
        )
        try context.environment.sessionRepository.insert(
            WorkSession(
                project: project,
                startTime: currentTwo,
                endTime: currentTwo.addingTimeInterval(7200),
                durationSeconds: 7200,
                resolvedHourlyRateSnapshot: Decimal(100)
            )
        )
        try context.environment.sessionRepository.insert(
            WorkSession(
                project: project,
                startTime: previousOne,
                endTime: previousOne.addingTimeInterval(1800),
                durationSeconds: 1800,
                resolvedHourlyRateSnapshot: Decimal(100)
            )
        )
        try context.environment.sessionRepository.insert(
            WorkSession(
                project: project,
                startTime: previousTwo,
                endTime: previousTwo.addingTimeInterval(1800),
                durationSeconds: 1800,
                resolvedHourlyRateSnapshot: Decimal(100)
            )
        )

        let viewModel = SessionsViewModel(appEnvironment: context.environment)
        viewModel.load()
        viewModel.activateCustomMode()
        viewModel.updateCustomStartDate(currentTwo)
        viewModel.updateCustomEndDate(currentOne)

        #expect(viewModel.filteredSessions.count == 2)
        #expect(viewModel.summaryCards.first?.subtitle == "+2ч 0м")
    }
}

@MainActor
private struct SessionsTestContext {
    let container: ModelContainer
    let environment: AppEnvironment

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self,
            Tag.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerSessionsTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(for: schema, configurations: [configuration])
        environment = AppEnvironment(modelContainer: container)
    }
}
