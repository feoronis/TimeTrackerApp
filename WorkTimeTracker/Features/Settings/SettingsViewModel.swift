import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let settingsRepository: SettingsRepository
    private let backupService: BackupService
    private let exportService: ExportService
    private let importService: ImportService
    private let cloudSyncStatusService: CloudSyncStatusService
    private let appEnvironment: AppEnvironment
    private(set) var settings: AppSettings?
    var defaultHourlyRateText = ""
    var currencyCode = "RUB"
    var timeFormat: TimeFormatOption = .hours24
    var firstDayOfWeek: FirstDayOfWeekOption = .monday
    var roundingMode: RoundingModeOption = .none
    var roundingMinutes = 0
    var longTimerReminderMinutes = 120
    var iCloudSyncEnabled = false
    var autoBackupEnabled = false
    var themeMode: ThemeModeOption = .system
    var accentColor: AccentColorOption = .blue
    var liquidGlassEnabled = true
    var feedbackMessage: String?
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.settingsRepository = appEnvironment.settingsRepository
        self.backupService = appEnvironment.backupService
        self.exportService = appEnvironment.exportService
        self.importService = appEnvironment.importService
        self.cloudSyncStatusService = appEnvironment.cloudSyncStatusService
    }

    func load() {
        appEnvironment.bootstrap()

        do {
            let settings = try settingsRepository.fetchOrCreateSettings()
            self.settings = settings
            defaultHourlyRateText = AppFormatters.decimalText(settings.defaultHourlyRate)
            currencyCode = settings.currencyCode
            timeFormat = TimeFormatOption(rawValue: settings.timeFormat) ?? .hours24
            firstDayOfWeek = FirstDayOfWeekOption(rawValue: settings.firstDayOfWeek) ?? .monday
            roundingMode = RoundingModeOption(rawValue: settings.roundingMode) ?? .none
            roundingMinutes = settings.roundingMinutes
            longTimerReminderMinutes = settings.longTimerReminderMinutes
            iCloudSyncEnabled = settings.iCloudSyncEnabled
            autoBackupEnabled = settings.autoBackupEnabled
            themeMode = ThemeModeOption(rawValue: settings.themeMode) ?? .system
            accentColor = AccentColorOption(rawValue: settings.resolvedAccentColorName) ?? .blue
            liquidGlassEnabled = settings.liquidGlassEnabled
            errorMessage = appEnvironment.bootstrapErrorMessage
            feedbackMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSettings() {
        guard let settings else {
            errorMessage = "Не удалось загрузить настройки."
            feedbackMessage = nil
            return
        }

        let trimmedRate = defaultHourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedRate = Decimal(string: trimmedRate.replacingOccurrences(of: ",", with: "."))

        guard trimmedRate.isEmpty == false, let parsedRate else {
            errorMessage = "Ставка по умолчанию должна быть числом."
            feedbackMessage = nil
            return
        }

        guard roundingMinutes >= 0 else {
            errorMessage = "Минуты округления не могут быть отрицательными."
            feedbackMessage = nil
            return
        }

        guard longTimerReminderMinutes >= 0 else {
            errorMessage = "Порог напоминания не может быть отрицательным."
            feedbackMessage = nil
            return
        }

        settings.defaultHourlyRate = parsedRate
        settings.currencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        settings.timeFormat = timeFormat.rawValue
        settings.firstDayOfWeek = firstDayOfWeek.rawValue
        settings.roundingMode = roundingMode.rawValue
        settings.roundingMinutes = roundingMinutes
        settings.longTimerReminderMinutes = longTimerReminderMinutes
        settings.iCloudSyncEnabled = iCloudSyncEnabled
        settings.autoBackupEnabled = autoBackupEnabled
        settings.themeMode = themeMode.rawValue
        settings.accentColorName = accentColor.rawValue
        settings.liquidGlassEnabled = liquidGlassEnabled
        settings.updatedAt = .now

        do {
            try settingsRepository.save()
            feedbackMessage = "Настройки сохранены."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func backupActionMessage() {
        do {
            let url = try backupService.createBackup()
            feedbackMessage = "Резервная копия создана: \(url.path)"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func exportJSONActionMessage() {
        do {
            let url = try exportService.exportJSON()
            feedbackMessage = "JSON экспорт сохранен: \(url.path)"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func exportCSVActionMessage() {
        do {
            let url = try exportService.exportCSV()
            feedbackMessage = "CSV экспорт сохранен: \(url.path)"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func importJSONActionMessage() {
        do {
            let summary = try importService.importJSON()
            try appEnvironment.timerService.restoreActiveSessionIfNeeded()
            if summary.settingsMerged {
                load()
            }
            feedbackMessage = summary.summaryText + (summary.settingsMerged ? " Настройки также обновлены." : "")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    var cloudSyncStatusText: String {
        switch cloudSyncStatusService.status(isEnabled: iCloudSyncEnabled) {
        case .disabled:
            return "Синхронизация через iCloud выключена"
        case .available:
            return "Синхронизация через iCloud включена"
        }
    }
}
