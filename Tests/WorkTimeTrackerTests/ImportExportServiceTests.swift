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

    @Test
    func backupCreatesJsonFileOnDisk() throws {
        let context = try ImportExportTestContext()
        let backupURL = try context.backupService.createBackup()

        #expect(FileManager.default.fileExists(atPath: backupURL.path))
        #expect(backupURL.pathExtension == "json")
    }

    @Test
    func automaticBackupKeepsOnlyNewestTwentyFiles() throws {
        let context = try ImportExportTestContext()
        let settings = try context.settingsRepository.fetchOrCreateSettings()
        settings.autoBackupEnabled = true
        settings.autoBackupDirectoryPath = context.backupDirectory.path
        settings.autoBackupDirectoryBookmark = nil
        try context.settingsRepository.save()

        for _ in 0..<25 {
            _ = try context.backupService.createAutomaticBackupIfEnabled()
        }

        let storedBackups = try FileManager.default.contentsOfDirectory(
            at: context.backupDirectory,
            includingPropertiesForKeys: nil
        )
        .filter { $0.lastPathComponent.hasPrefix("backup-") && $0.pathExtension == "json" }

        #expect(storedBackups.count == 20)
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
    let backupService: BackupService
    let importService: ImportService
    let backupDirectory: URL

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self,
            Tag.self
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
        let tagRepository = TagRepository(modelContext: modelContext)
        backupDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkTimeTrackerBackupTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        let applicationSupportDirectory = backupDirectory
        exportService = ExportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            tagRepository: tagRepository,
            sessionCalculator: SessionCalculator()
        )
        backupService = BackupService(
            exportService: exportService,
            settingsRepository: settingsRepository,
            applicationSupportDirectoryProvider: { applicationSupportDirectory }
        )
        importService = ImportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            tagRepository: tagRepository
        )
    }
}
