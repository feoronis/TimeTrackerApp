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
    var themeMode: String
    var accentColorName: String?
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
        themeMode: String = "system",
        accentColorName: String? = "blue",
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
        self.themeMode = themeMode
        self.accentColorName = accentColorName
        self.liquidGlassEnabled = liquidGlassEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var resolvedAccentColorName: String {
        accentColorName ?? "blue"
    }
}
