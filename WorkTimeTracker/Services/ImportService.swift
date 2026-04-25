import AppKit
import Foundation
import UniformTypeIdentifiers

enum ImportServiceError: LocalizedError {
    case cancelled
    case duplicateProjectIDs
    case duplicateSessionIDs
    case duplicateDayNoteIDs
    case multipleActiveSessionsInImport
    case activeSessionConflict

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Импорт отменен."
        case .duplicateProjectIDs:
            return "Файл импорта содержит повторяющиеся идентификаторы проектов."
        case .duplicateSessionIDs:
            return "Файл импорта содержит повторяющиеся идентификаторы сессий."
        case .duplicateDayNoteIDs:
            return "Файл импорта содержит повторяющиеся идентификаторы заметок дня."
        case .multipleActiveSessionsInImport:
            return "Файл импорта содержит несколько активных сессий."
        case .activeSessionConflict:
            return "Нельзя импортировать активную сессию, пока в приложении уже есть активный таймер."
        }
    }
}

@MainActor
struct ImportService {
    private let projectRepository: ProjectRepository
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let dayNoteRepository: DayNoteRepository

    init(
        projectRepository: ProjectRepository,
        sessionRepository: SessionRepository,
        settingsRepository: SettingsRepository,
        dayNoteRepository: DayNoteRepository
    ) {
        self.projectRepository = projectRepository
        self.sessionRepository = sessionRepository
        self.settingsRepository = settingsRepository
        self.dayNoteRepository = dayNoteRepository
    }

    func importJSON() throws -> ImportSummary {
        let url = try chooseImportFile()
        let data = try Data(contentsOf: url)
        let snapshot = try JSONDecoder.snapshotDecoder.decode(AppDataSnapshot.self, from: data)
        try validate(snapshot: snapshot)
        return try merge(snapshot: snapshot)
    }

    func merge(snapshot: AppDataSnapshot) throws -> ImportSummary {
        try validate(snapshot: snapshot)

        let existingProjects = try projectRepository.fetchAllByID()
        let existingSessions = try sessionRepository.fetchAllByID()
        let existingDayNotes = try dayNoteRepository.fetchAll()
        let existingDayNotesByID = Dictionary(uniqueKeysWithValues: existingDayNotes.map { ($0.id, $0) })
        var existingDayNoteDates = Set(existingDayNotes.map { Calendar.current.startOfDay(for: $0.date) })
        var allProjectsByID = existingProjects
        let existingActiveSession = try sessionRepository.fetchActiveSession()

        if existingActiveSession != nil && snapshot.sessions.contains(where: { $0.endTime == nil }) {
            throw ImportServiceError.activeSessionConflict
        }

        var importedProjects = 0
        var skippedProjects = 0
        var importedSessions = 0
        var skippedSessions = 0
        var importedDayNotes = 0
        var skippedDayNotes = 0
        var settingsMerged = false

        for projectSnapshot in snapshot.projects {
            guard allProjectsByID[projectSnapshot.id] == nil else {
                skippedProjects += 1
                continue
            }

            let project = Project(
                id: projectSnapshot.id,
                name: projectSnapshot.name,
                colorHex: projectSnapshot.colorHex,
                iconName: projectSnapshot.iconName,
                hourlyRate: projectSnapshot.hourlyRate,
                isArchived: projectSnapshot.isArchived,
                notes: projectSnapshot.notes,
                createdAt: projectSnapshot.createdAt,
                updatedAt: projectSnapshot.updatedAt
            )
            try projectRepository.insert(project)
            allProjectsByID[project.id] = project
            importedProjects += 1
        }

        for dayNoteSnapshot in snapshot.dayNotes {
            let normalizedDate = Calendar.current.startOfDay(for: dayNoteSnapshot.date)

            guard existingDayNotesByID[dayNoteSnapshot.id] == nil,
                  existingDayNoteDates.contains(normalizedDate) == false else {
                skippedDayNotes += 1
                continue
            }

            let dayNote = DayNote(
                id: dayNoteSnapshot.id,
                date: dayNoteSnapshot.date,
                note: dayNoteSnapshot.note,
                createdAt: dayNoteSnapshot.createdAt,
                updatedAt: dayNoteSnapshot.updatedAt
            )
            try dayNoteRepository.insert(dayNote)
            existingDayNoteDates.insert(normalizedDate)
            importedDayNotes += 1
        }

        for sessionSnapshot in snapshot.sessions {
            guard existingSessions[sessionSnapshot.id] == nil else {
                skippedSessions += 1
                continue
            }

            let session = WorkSession(
                id: sessionSnapshot.id,
                project: sessionSnapshot.projectID.flatMap { allProjectsByID[$0] },
                startTime: sessionSnapshot.startTime,
                endTime: sessionSnapshot.endTime,
                durationSeconds: sessionSnapshot.durationSeconds,
                note: sessionSnapshot.note,
                tags: sessionSnapshot.tags,
                customHourlyRate: sessionSnapshot.customHourlyRate,
                resolvedHourlyRateSnapshot: sessionSnapshot.resolvedHourlyRateSnapshot,
                createdAt: sessionSnapshot.createdAt,
                updatedAt: sessionSnapshot.updatedAt
            )
            try sessionRepository.insert(session)
            importedSessions += 1
        }

        if let importedSettings = snapshot.settings {
            let currentSettings = try settingsRepository.fetchOrCreateSettings()
            currentSettings.defaultHourlyRate = importedSettings.defaultHourlyRate
            currentSettings.currencyCode = importedSettings.currencyCode
            currentSettings.timeFormat = importedSettings.timeFormat
            currentSettings.firstDayOfWeek = importedSettings.firstDayOfWeek
            currentSettings.roundingMode = importedSettings.roundingMode
            currentSettings.roundingMinutes = importedSettings.roundingMinutes
            currentSettings.longTimerReminderMinutes = importedSettings.longTimerReminderMinutes
            currentSettings.iCloudSyncEnabled = importedSettings.iCloudSyncEnabled
            currentSettings.autoBackupEnabled = importedSettings.autoBackupEnabled
            currentSettings.themeMode = importedSettings.themeMode
            currentSettings.accentColorName = importedSettings.accentColorName
            currentSettings.liquidGlassEnabled = importedSettings.liquidGlassEnabled
            currentSettings.updatedAt = .now
            try settingsRepository.save()
            settingsMerged = true
        }

        return ImportSummary(
            importedProjects: importedProjects,
            skippedProjects: skippedProjects,
            importedSessions: importedSessions,
            skippedSessions: skippedSessions,
            importedDayNotes: importedDayNotes,
            skippedDayNotes: skippedDayNotes,
            settingsMerged: settingsMerged
        )
    }

    func validate(snapshot: AppDataSnapshot) throws {
        guard Set(snapshot.projects.map(\.id)).count == snapshot.projects.count else {
            throw ImportServiceError.duplicateProjectIDs
        }

        guard Set(snapshot.sessions.map(\.id)).count == snapshot.sessions.count else {
            throw ImportServiceError.duplicateSessionIDs
        }

        guard Set(snapshot.dayNotes.map(\.id)).count == snapshot.dayNotes.count else {
            throw ImportServiceError.duplicateDayNoteIDs
        }

        let activeSessionCount = snapshot.sessions.filter { $0.endTime == nil }.count
        guard activeSessionCount <= 1 else {
            throw ImportServiceError.multipleActiveSessionsInImport
        }
    }

    private func chooseImportFile() throws -> URL {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else {
            throw ImportServiceError.cancelled
        }

        return url
    }
}
