import Foundation
import SwiftData

@Model
final class AppSettings {
    var defaultHourlyRate: Decimal
    var currencyCode: String
    var timeFormat: String
    var firstDayOfWeek: Int
    var roundingMode: String
    var roundingMinutes: Int
    var longTimerReminderMinutes: Int
    var iCloudSyncEnabled: Bool
    var autoBackupEnabled: Bool
    var autoBackupDirectoryPath: String?
    var autoBackupDirectoryBookmark: Data?
    var themeMode: String
    var liquidGlassEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        defaultHourlyRate: Decimal = .zero,
        currencyCode: String = "RUB",
        timeFormat: String = "24h",
        firstDayOfWeek: Int = 2,
        roundingMode: String = "none",
        roundingMinutes: Int = 0,
        longTimerReminderMinutes: Int = 120,
        iCloudSyncEnabled: Bool = false,
        autoBackupEnabled: Bool = false,
        autoBackupDirectoryPath: String? = nil,
        autoBackupDirectoryBookmark: Data? = nil,
        themeMode: String = "system",
        liquidGlassEnabled: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
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
        self.autoBackupDirectoryBookmark = autoBackupDirectoryBookmark
        self.themeMode = themeMode
        self.liquidGlassEnabled = liquidGlassEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
