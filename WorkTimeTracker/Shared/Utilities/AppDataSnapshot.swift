import Foundation

struct AppDataSnapshot: Codable {
    let version: Int
    let exportedAt: Date
    let settings: AppSettingsSnapshot?
    let projects: [ProjectSnapshot]
    let sessions: [WorkSessionSnapshot]
    let dayNotes: [DayNoteSnapshot]

    init(
        version: Int = 1,
        exportedAt: Date = .now,
        settings: AppSettingsSnapshot?,
        projects: [ProjectSnapshot],
        sessions: [WorkSessionSnapshot],
        dayNotes: [DayNoteSnapshot]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.settings = settings
        self.projects = projects
        self.sessions = sessions
        self.dayNotes = dayNotes
    }
}

struct AppSettingsSnapshot: Codable {
    let defaultHourlyRate: Decimal
    let currencyCode: String
    let timeFormat: String
    let firstDayOfWeek: Int
    let roundingMode: String
    let roundingMinutes: Int
    let longTimerReminderMinutes: Int
    let iCloudSyncEnabled: Bool
    let autoBackupEnabled: Bool
    let themeMode: String
    let accentColorName: String
    let liquidGlassEnabled: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        defaultHourlyRate: Decimal,
        currencyCode: String,
        timeFormat: String,
        firstDayOfWeek: Int,
        roundingMode: String,
        roundingMinutes: Int,
        longTimerReminderMinutes: Int,
        iCloudSyncEnabled: Bool,
        autoBackupEnabled: Bool,
        themeMode: String,
        accentColorName: String,
        liquidGlassEnabled: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.defaultHourlyRate = defaultHourlyRate
        self.currencyCode = currencyCode
        self.timeFormat = timeFormat
        self.firstDayOfWeek = firstDayOfWeek
        self.roundingMode = roundingMode
        self.roundingMinutes = roundingMinutes
        self.longTimerReminderMinutes = longTimerReminderMinutes
        self.iCloudSyncEnabled = iCloudSyncEnabled
        self.autoBackupEnabled = autoBackupEnabled
        self.themeMode = themeMode
        self.accentColorName = accentColorName
        self.liquidGlassEnabled = liquidGlassEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(settings: AppSettings) {
        defaultHourlyRate = settings.defaultHourlyRate
        currencyCode = settings.currencyCode
        timeFormat = settings.timeFormat
        firstDayOfWeek = settings.firstDayOfWeek
        roundingMode = settings.roundingMode
        roundingMinutes = settings.roundingMinutes
        longTimerReminderMinutes = settings.longTimerReminderMinutes
        iCloudSyncEnabled = settings.iCloudSyncEnabled
        autoBackupEnabled = settings.autoBackupEnabled
        themeMode = settings.themeMode
        accentColorName = settings.resolvedAccentColorName
        liquidGlassEnabled = settings.liquidGlassEnabled
        createdAt = settings.createdAt
        updatedAt = settings.updatedAt
    }
}

struct ProjectSnapshot: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let iconName: String?
    let hourlyRate: Decimal?
    let isArchived: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        name: String,
        colorHex: String,
        iconName: String?,
        hourlyRate: Decimal?,
        isArchived: Bool,
        notes: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.hourlyRate = hourlyRate
        self.isArchived = isArchived
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(project: Project) {
        id = project.id
        name = project.name
        colorHex = project.colorHex
        iconName = project.iconName
        hourlyRate = project.hourlyRate
        isArchived = project.isArchived
        notes = project.notes
        createdAt = project.createdAt
        updatedAt = project.updatedAt
    }
}

struct WorkSessionSnapshot: Codable {
    let id: UUID
    let projectID: UUID?
    let startTime: Date
    let endTime: Date?
    let durationSeconds: TimeInterval
    let note: String?
    let tags: [String]
    let customHourlyRate: Decimal?
    let resolvedHourlyRateSnapshot: Decimal
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        projectID: UUID?,
        startTime: Date,
        endTime: Date?,
        durationSeconds: TimeInterval,
        note: String?,
        tags: [String],
        customHourlyRate: Decimal?,
        resolvedHourlyRateSnapshot: Decimal,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.projectID = projectID
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.note = note
        self.tags = tags
        self.customHourlyRate = customHourlyRate
        self.resolvedHourlyRateSnapshot = resolvedHourlyRateSnapshot
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(session: WorkSession) {
        id = session.id
        projectID = session.project?.id
        startTime = session.startTime
        endTime = session.endTime
        durationSeconds = session.durationSeconds
        note = session.note
        tags = session.tags
        customHourlyRate = session.customHourlyRate
        resolvedHourlyRateSnapshot = session.resolvedHourlyRateSnapshot
        createdAt = session.createdAt
        updatedAt = session.updatedAt
    }
}

struct DayNoteSnapshot: Codable {
    let id: UUID
    let date: Date
    let note: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        date: Date,
        note: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(dayNote: DayNote) {
        id = dayNote.id
        date = dayNote.date
        note = dayNote.note
        createdAt = dayNote.createdAt
        updatedAt = dayNote.updatedAt
    }
}

struct ImportSummary {
    let importedProjects: Int
    let skippedProjects: Int
    let importedSessions: Int
    let skippedSessions: Int
    let importedDayNotes: Int
    let skippedDayNotes: Int
    let settingsMerged: Bool

    var summaryText: String {
        "Импорт завершен: проектов \(importedProjects), пропущено проектов \(skippedProjects), сессий \(importedSessions), пропущено сессий \(skippedSessions), заметок дня \(importedDayNotes), пропущено заметок \(skippedDayNotes)."
    }
}
