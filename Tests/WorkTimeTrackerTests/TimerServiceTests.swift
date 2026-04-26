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

    @Test
    func pauseAndResumeExcludePausedTimeFromDuration() throws {
        let context = try TestContext()
        let project = Project(name: "Клиент A")
        let startDate = Date(timeIntervalSince1970: 1_000)
        let pauseDate = Date(timeIntervalSince1970: 1_300)
        let resumeDate = Date(timeIntervalSince1970: 1_900)
        let endDate = Date(timeIntervalSince1970: 2_500)

        try context.projectRepository.insert(project)

        _ = try context.timerService.startTimer(
            project: project,
            note: nil,
            tags: [],
            customHourlyRate: nil,
            startDate: startDate
        )

        let pausedSession = try context.timerService.pauseActiveTimer(at: pauseDate)
        #expect(pausedSession.isPaused == true)
        #expect(context.timerService.elapsedDuration(for: pausedSession, at: pauseDate) == 300)

        let resumedSession = try context.timerService.resumeActiveTimer(at: resumeDate)
        #expect(resumedSession.isPaused == false)
        #expect(resumedSession.accumulatedPausedSeconds == 600)

        let finishedSession = try context.timerService.stopActiveTimer(at: endDate)

        #expect(finishedSession.durationSeconds == 900)
        #expect(finishedSession.pausedAt == nil)
    }

    @Test
    func updatingActiveSessionRateRefreshesSnapshotIntentionally() throws {
        let context = try TestContext()
        let project = Project(name: "Клиент A", hourlyRate: Decimal(200))

        try context.projectRepository.insert(project)

        _ = try context.timerService.startTimer(
            project: project,
            note: nil,
            tags: [],
            customHourlyRate: nil
        )

        let updatedSession = try context.timerService.updateActiveSessionRate(customHourlyRate: Decimal(350))

        #expect(updatedSession.customHourlyRate == Decimal(350))
        #expect(updatedSession.resolvedHourlyRateSnapshot == Decimal(350))
        #expect(context.timerService.activeSession?.resolvedHourlyRateSnapshot == Decimal(350))

        let resetSession = try context.timerService.updateActiveSessionRate(customHourlyRate: nil)

        #expect(resetSession.customHourlyRate == nil)
        #expect(resetSession.resolvedHourlyRateSnapshot == Decimal(200))
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
            DayNote.self,
            Tag.self
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
