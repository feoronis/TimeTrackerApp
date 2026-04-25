import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct ImportExportServiceTests {
    @Test
    func snapshotContainsCurrentData() throws {
        let context = try ImportExportTestContext()
        let project = Project(name: "Проект экспорта")
        let session = WorkSession(
            project: project,
            startTime: Date(timeIntervalSince1970: 1_000),
            endTime: Date(timeIntervalSince1970: 4_600),
            durationSeconds: 3_600,
            resolvedHourlyRateSnapshot: Decimal(120)
        )
        let dayNote = DayNote(date: Date(timeIntervalSince1970: 0), note: "Заметка дня")

        try context.projectRepository.insert(project)
        try context.sessionRepository.insert(session)
        try context.dayNoteRepository.insert(dayNote)

        let snapshot = try context.exportService.buildSnapshot()

        #expect(snapshot.projects.count == 1)
        #expect(snapshot.sessions.count == 1)
        #expect(snapshot.dayNotes.count == 1)
        #expect(snapshot.settings != nil)
    }

    @Test
    func importMergesOnlyMissingRecords() throws {
        let context = try ImportExportTestContext()
        let existingProject = Project(name: "Существующий", createdAt: .now, updatedAt: .now)
        try context.projectRepository.insert(existingProject)

        let importedProjectID = UUID()
        let duplicateSessionID = UUID()

        let snapshot = AppDataSnapshot(
            settings: AppSettingsSnapshot(settings: try context.settingsRepository.fetchOrCreateSettings()),
            projects: [
                ProjectSnapshot(
                    id: importedProjectID,
                    name: "Импортированный проект",
                    colorHex: "#FFFFFF",
                    iconName: "folder",
                    hourlyRate: Decimal(200),
                    isArchived: false,
                    notes: nil,
                    createdAt: .now,
                    updatedAt: .now
                )
            ],
            sessions: [
                WorkSessionSnapshot(
                    id: duplicateSessionID,
                    projectID: importedProjectID,
                    startTime: Date(timeIntervalSince1970: 10_000),
                    endTime: Date(timeIntervalSince1970: 13_600),
                    durationSeconds: 3_600,
                    note: "Новая сессия",
                    tags: ["import"],
                    customHourlyRate: nil,
                    resolvedHourlyRateSnapshot: Decimal(200),
                    createdAt: .now,
                    updatedAt: .now
                )
            ],
            dayNotes: [
                DayNoteSnapshot(
                    id: UUID(),
                    date: Date(timeIntervalSince1970: 0),
                    note: "Импортированная заметка",
                    createdAt: .now,
                    updatedAt: .now
                )
            ]
        )

        let summary = try context.importService.merge(snapshot: snapshot)

        #expect(summary.importedProjects == 1)
        #expect(summary.importedSessions == 1)
        #expect(summary.importedDayNotes == 1)
        #expect(try context.projectRepository.fetchAll().count == 2)
        #expect(try context.sessionRepository.fetchAll().count == 1)
        #expect(try context.dayNoteRepository.fetchAll().count == 1)
    }

    @Test
    func importValidationRejectsMultipleActiveSessions() throws {
        let context = try ImportExportTestContext()

        let snapshot = AppDataSnapshot(
            settings: nil,
            projects: [],
            sessions: [
                WorkSessionSnapshot(
                    id: UUID(),
                    projectID: nil,
                    startTime: .now,
                    endTime: nil,
                    durationSeconds: 0,
                    note: nil,
                    tags: [],
                    customHourlyRate: nil,
                    resolvedHourlyRateSnapshot: .zero,
                    createdAt: .now,
                    updatedAt: .now
                ),
                WorkSessionSnapshot(
                    id: UUID(),
                    projectID: nil,
                    startTime: .now.addingTimeInterval(-100),
                    endTime: nil,
                    durationSeconds: 0,
                    note: nil,
                    tags: [],
                    customHourlyRate: nil,
                    resolvedHourlyRateSnapshot: .zero,
                    createdAt: .now,
                    updatedAt: .now
                )
            ],
            dayNotes: []
        )

        #expect(throws: ImportServiceError.multipleActiveSessionsInImport) {
            try context.importService.validate(snapshot: snapshot)
        }
    }
}

@MainActor
private struct ImportExportTestContext {
    let container: ModelContainer
    let projectRepository: ProjectRepository
    let sessionRepository: SessionRepository
    let settingsRepository: SettingsRepository
    let dayNoteRepository: DayNoteRepository
    let exportService: ExportService
    let importService: ImportService

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerImportExportTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        container = try ModelContainer(for: schema, configurations: [configuration])

        let modelContext = container.mainContext
        projectRepository = ProjectRepository(modelContext: modelContext)
        sessionRepository = SessionRepository(modelContext: modelContext)
        settingsRepository = SettingsRepository(modelContext: modelContext)
        dayNoteRepository = DayNoteRepository(modelContext: modelContext)
        exportService = ExportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            sessionCalculator: SessionCalculator()
        )
        importService = ImportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository
        )
    }
}
