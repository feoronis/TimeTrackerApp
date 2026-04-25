import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct TimerServiceTests {
    @Test
    func timerStartPersistsActiveSessionImmediately() throws {
        let context = try TestContext()
        let project = Project(name: "Клиент A")

        try context.projectRepository.insert(project)

        let startedSession = try context.timerService.startTimer(
            project: project,
            note: "Фокусный блок",
            tags: ["глубокая-работа"],
            customHourlyRate: nil
        )

        let persistedActiveSession = try context.sessionRepository.fetchActiveSession()

        #expect(startedSession.id == persistedActiveSession?.id)
        #expect(persistedActiveSession?.endTime == nil)
        #expect(context.timerService.activeSession?.id == startedSession.id)
    }

    @Test
    func timerServiceAllowsOnlyOneActiveSession() throws {
        let context = try TestContext()
        let project = Project(name: "Клиент A")

        try context.projectRepository.insert(project)
        try context.timerService.startTimer(
            project: project,
            note: nil,
            tags: [],
            customHourlyRate: nil
        )

        #expect(throws: TimerServiceError.self) {
            try context.timerService.startTimer(
                project: project,
                note: nil,
                tags: [],
                customHourlyRate: nil
            )
        }
    }

    @Test
    func timerStopFinalizesSession() throws {
        let context = try TestContext()
        let project = Project(name: "Клиент A")
        let startDate = Date(timeIntervalSince1970: 1_000)
        let endDate = Date(timeIntervalSince1970: 1_600)

        try context.projectRepository.insert(project)

        _ = try context.timerService.startTimer(
            project: project,
            note: "Работа по задаче",
            tags: ["клиент"],
            customHourlyRate: Decimal(150),
            startDate: startDate
        )

        let finishedSession = try context.timerService.stopActiveTimer(at: endDate)

        #expect(finishedSession.endTime == endDate)
        #expect(finishedSession.durationSeconds == 600)
        #expect(context.timerService.activeSession == nil)
        #expect(try context.sessionRepository.fetchActiveSession() == nil)
    }
}

@MainActor
private struct TestContext {
    let container: ModelContainer
    let projectRepository: ProjectRepository
    let sessionRepository: SessionRepository
    let settingsRepository: SettingsRepository
    let timerService: TimerService

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(for: schema, configurations: [configuration])

        let modelContext = container.mainContext
        projectRepository = ProjectRepository(modelContext: modelContext)
        sessionRepository = SessionRepository(modelContext: modelContext)
        settingsRepository = SettingsRepository(modelContext: modelContext)
        timerService = TimerService(
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            sessionCalculator: SessionCalculator()
        )
    }
}
