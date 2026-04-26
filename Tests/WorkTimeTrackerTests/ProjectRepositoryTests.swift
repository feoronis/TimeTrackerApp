import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct ProjectRepositoryTests {
    @Test
    func deletingProjectRemovesLinkedSessions() throws {
        let context = try ProjectRepositoryTestContext()
        let project = Project(name: "Клиент A")
        let session = WorkSession(
            project: project,
            startTime: Date(timeIntervalSince1970: 1_700_000_000),
            endTime: Date(timeIntervalSince1970: 1_700_003_600),
            durationSeconds: 3_600,
            resolvedHourlyRateSnapshot: Decimal(150)
        )

        try context.projectRepository.insert(project)
        try context.sessionRepository.insert(session)

        let linkedSessions = try context.sessionRepository.fetchSessions(projectID: project.id)
        try context.sessionRepository.delete(linkedSessions)
        try context.projectRepository.delete(project)

        let persistedSessions = try context.sessionRepository.fetchAll()

        #expect(persistedSessions.isEmpty)
    }
}

@MainActor
private struct ProjectRepositoryTestContext {
    let container: ModelContainer
    let projectRepository: ProjectRepository
    let sessionRepository: SessionRepository

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self,
            Tag.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerProjectRepositoryTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(for: schema, configurations: [configuration])

        let modelContext = container.mainContext
        projectRepository = ProjectRepository(modelContext: modelContext)
        sessionRepository = SessionRepository(modelContext: modelContext)
    }
}
