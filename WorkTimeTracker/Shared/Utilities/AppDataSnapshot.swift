import Foundation

struct AppDataSnapshot: Codable {
    let version: Int
    let exportedAt: Date
    let settings: AppSettingsSnapshot?
    let projects: [ProjectSnapshot]
    let sessions: [WorkSessionSnapshot]
    let dayNotes: [DayNoteSnapshot]
    let tags: [TagSnapshot]

    init(
        version: Int = 2,
        exportedAt: Date = .now,
        settings: AppSettingsSnapshot?,
        projects: [ProjectSnapshot],
        sessions: [WorkSessionSnapshot],
        dayNotes: [DayNoteSnapshot],
        tags: [TagSnapshot] = []
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.settings = settings
        self.projects = projects
        self.sessions = sessions
        self.dayNotes = dayNotes
        self.tags = tags
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case exportedAt
        case settings
        case projects
        case sessions
        case dayNotes
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        exportedAt = try container.decodeIfPresent(Date.self, forKey: .exportedAt) ?? .now
        settings = try container.decodeIfPresent(AppSettingsSnapshot.self, forKey: .settings)
        projects = try container.decodeIfPresent([ProjectSnapshot].self, forKey: .projects) ?? []
        sessions = try container.decodeIfPresent([WorkSessionSnapshot].self, forKey: .sessions) ?? []
        dayNotes = try container.decodeIfPresent([DayNoteSnapshot].self, forKey: .dayNotes) ?? []
        tags = try container.decodeIfPresent([TagSnapshot].self, forKey: .tags) ?? []
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
    let autoBackupDirectoryPath: String?
    let themeMode: String
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
        autoBackupDirectoryPath: String?,
        themeMode: String,
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
        self.autoBackupDirectoryPath = autoBackupDirectoryPath
        self.themeMode = themeMode
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
        autoBackupDirectoryPath = settings.autoBackupDirectoryPath
        themeMode = settings.themeMode
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
    let fixedIncomeAmount: Decimal?
    let pausedAt: Date?
    let accumulatedPausedSeconds: TimeInterval
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
        fixedIncomeAmount: Decimal? = nil,
        pausedAt: Date? = nil,
        accumulatedPausedSeconds: TimeInterval = 0,
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
        self.fixedIncomeAmount = fixedIncomeAmount
        self.pausedAt = pausedAt
        self.accumulatedPausedSeconds = accumulatedPausedSeconds
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
        fixedIncomeAmount = session.fixedIncomeAmount
        pausedAt = session.pausedAt
        accumulatedPausedSeconds = session.accumulatedPausedSeconds
        createdAt = session.createdAt
        updatedAt = session.updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case projectID
        case startTime
        case endTime
        case durationSeconds
        case note
        case tags
        case customHourlyRate
        case resolvedHourlyRateSnapshot
        case fixedIncomeAmount
        case pausedAt
        case accumulatedPausedSeconds
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectID = try container.decodeIfPresent(UUID.self, forKey: .projectID)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        customHourlyRate = try container.decodeIfPresent(Decimal.self, forKey: .customHourlyRate)
        resolvedHourlyRateSnapshot = try container.decode(Decimal.self, forKey: .resolvedHourlyRateSnapshot)
        fixedIncomeAmount = try container.decodeIfPresent(Decimal.self, forKey: .fixedIncomeAmount)
        pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
        accumulatedPausedSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .accumulatedPausedSeconds) ?? 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct TagSnapshot: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        name: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(tag: Tag) {
        id = tag.id
        name = tag.name
        createdAt = tag.createdAt
        updatedAt = tag.updatedAt
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
    let importedTags: Int
    let skippedTags: Int
    let settingsMerged: Bool

    var summaryText: String {
        "Импорт завершен: проектов \(importedProjects), пропущено проектов \(skippedProjects), сессий \(importedSessions), пропущено сессий \(skippedSessions), заметок дня \(importedDayNotes), пропущено заметок \(skippedDayNotes), тегов \(importedTags), пропущено тегов \(skippedTags)."
    }
}
