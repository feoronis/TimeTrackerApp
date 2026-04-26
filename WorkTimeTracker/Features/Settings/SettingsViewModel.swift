import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let settingsRepository: SettingsRepository
    private let sessionRepository: SessionRepository
    private let tagRepository: TagRepository
    private let backupService: BackupService
    private let exportService: ExportService
    private let importService: ImportService
    private let cloudSyncStatusService: CloudSyncStatusService
    private let appEnvironment: AppEnvironment
    private(set) var settings: AppSettings?
    private(set) var tags: [Tag] = []
    var defaultHourlyRateText = ""
    var currencyCode = "RUB"
    var timeFormat: TimeFormatOption = .hours24
    var firstDayOfWeek: FirstDayOfWeekOption = .monday
    var roundingMode: RoundingModeOption = .none
    var roundingMinutes = 0
    var longTimerReminderMinutes = 120
    var iCloudSyncEnabled = false
    var autoBackupEnabled = false
    var autoBackupDirectoryPath: String?
    var themeMode: ThemeModeOption = .system
    var liquidGlassEnabled = true
    var cloudSyncStatus: CloudSyncStatusService.SyncStatus = .disabled
    var selectedSection: SettingsSection = .general
    var newTagName = ""
    var feedbackMessage: String?
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
        self.settingsRepository = appEnvironment.settingsRepository
        self.sessionRepository = appEnvironment.sessionRepository
        self.tagRepository = appEnvironment.tagRepository
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
            tags = try tagRepository.fetchAll()
            defaultHourlyRateText = AppFormatters.decimalText(settings.defaultHourlyRate)
            currencyCode = settings.currencyCode
            timeFormat = TimeFormatOption(rawValue: settings.timeFormat) ?? .hours24
            firstDayOfWeek = FirstDayOfWeekOption(rawValue: settings.firstDayOfWeek) ?? .monday
            roundingMode = RoundingModeOption(rawValue: settings.roundingMode) ?? .none
            roundingMinutes = settings.roundingMinutes
            longTimerReminderMinutes = settings.longTimerReminderMinutes
            iCloudSyncEnabled = settings.iCloudSyncEnabled
            autoBackupEnabled = settings.autoBackupEnabled
            autoBackupDirectoryPath = settings.autoBackupDirectoryPath
            themeMode = ThemeModeOption(rawValue: settings.themeMode) ?? .system
            liquidGlassEnabled = settings.liquidGlassEnabled
            errorMessage = appEnvironment.bootstrapErrorMessage
            feedbackMessage = nil
            refreshCloudSyncStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSettings() {
        persistSettings(showFeedback: true)
    }

    func saveSettingsSilently() {
        persistSettings(showFeedback: false)
    }

    private func persistSettings(showFeedback: Bool) {
        guard let settings else {
            errorMessage = "Не удалось загрузить настройки."
            if showFeedback { feedbackMessage = nil }
            return
        }

        let trimmedRate = defaultHourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedRate = Decimal(string: trimmedRate.replacingOccurrences(of: ",", with: "."))

        guard trimmedRate.isEmpty == false, let parsedRate else {
            errorMessage = "Ставка по умолчанию должна быть числом."
            if showFeedback { feedbackMessage = nil }
            return
        }

        guard roundingMinutes >= 0 else {
            errorMessage = "Минуты округления не могут быть отрицательными."
            if showFeedback { feedbackMessage = nil }
            return
        }

        guard longTimerReminderMinutes >= 0 else {
            errorMessage = "Порог напоминания не может быть отрицательным."
            if showFeedback { feedbackMessage = nil }
            return
        }

        let previousICloudPreference = CloudSyncPreferences.isEnabled
        let wasAutoBackupEnabled = settings.autoBackupEnabled

        settings.defaultHourlyRate = parsedRate
        settings.currencyCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        settings.timeFormat = timeFormat.rawValue
        settings.firstDayOfWeek = firstDayOfWeek.rawValue
        settings.roundingMode = roundingMode.rawValue
        settings.roundingMinutes = roundingMinutes
        settings.longTimerReminderMinutes = longTimerReminderMinutes
        settings.iCloudSyncEnabled = iCloudSyncEnabled
        settings.autoBackupEnabled = autoBackupEnabled
        settings.autoBackupDirectoryPath = autoBackupDirectoryPath
        settings.themeMode = themeMode.rawValue
        settings.liquidGlassEnabled = liquidGlassEnabled
        settings.updatedAt = .now

        do {
            try settingsRepository.save()
            appEnvironment.syncAppearancePreferences(from: settings)
            refreshCloudSyncStatus()

            if autoBackupEnabled && wasAutoBackupEnabled == false {
                _ = try? backupService.createAutomaticBackupIfEnabled()
            }

            if showFeedback, previousICloudPreference != iCloudSyncEnabled {
                feedbackMessage = "Настройка iCloud сохранена. Перезапустите приложение, чтобы полностью применить режим синхронизации."
            } else {
                feedbackMessage = showFeedback ? "Настройки сохранены." : nil
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            if showFeedback { feedbackMessage = nil }
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
            appEnvironment.notifyDataChanged()
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
        switch cloudSyncStatus {
        case .disabled:
            return "Синхронизация через iCloud выключена"
        case .restartRequiredToEnable:
            return "CloudKit-синхронизация готова к включению. Перезапустите приложение, чтобы подключить iCloud."
        case .restartRequiredToDisable:
            return "CloudKit-синхронизация пока ещё активна. Перезапустите приложение, чтобы отключить iCloud."
        case .active:
            return "Синхронизация через iCloud работает. Изменения автоматически передаются через CloudKit."
        case .unavailableNoAccount:
            return "Войдите в iCloud на этом Mac, чтобы синхронизация начала работать."
        case .unavailableRestricted:
            return "iCloud недоступен из-за системных ограничений или настроек учётной записи."
        case .unavailableTemporarily:
            return "Состояние iCloud сейчас определить не удалось. Повторите проверку чуть позже."
        case .unavailableConfiguration(let description):
            return "CloudKit не удалось запустить: \(description)"
        }
    }

    func refreshCloudSyncStatus() {
        let isEnabled = iCloudSyncEnabled

        Task { @MainActor [weak self] in
            guard let self else { return }
            let resolvedStatus = await cloudSyncStatusService.status(isEnabled: isEnabled)

            guard self.iCloudSyncEnabled == isEnabled else { return }
            self.cloudSyncStatus = resolvedStatus
        }
    }

    var reminderOptions: [Int] {
        [15, 30, 45, 60, 90, 120, 180]
    }

    var autoBackupLocationText: String {
        backupService.resolvedBackupDirectoryPath(for: settings)
    }

    var defaultAutoBackupLocationText: String {
        backupService.defaultBackupDirectoryPath()
    }

    func selectAutoBackupFolder() {
        guard let settings else {
            errorMessage = "Не удалось загрузить настройки."
            feedbackMessage = nil
            return
        }

        do {
            let selection = try backupService.chooseBackupDirectory()
            settings.autoBackupDirectoryPath = selection.path
            settings.autoBackupDirectoryBookmark = selection.bookmarkData
            settings.updatedAt = .now
            autoBackupDirectoryPath = selection.path
            try settingsRepository.save()

            if autoBackupEnabled {
                let backupURL = try backupService.createAutomaticBackupIfEnabled()
                feedbackMessage = backupURL.map { "Папка для автобэкапов сохранена. Создана резервная копия: \($0.path)" }
                    ?? "Папка для автобэкапов сохранена."
            } else {
                feedbackMessage = "Папка для автобэкапов сохранена."
            }
            errorMessage = nil
        } catch {
            if let backupError = error as? BackupServiceError, backupError == .cancelled {
                return
            }

            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func resetAutoBackupFolder() {
        guard let settings else {
            errorMessage = "Не удалось загрузить настройки."
            feedbackMessage = nil
            return
        }

        do {
            settings.autoBackupDirectoryPath = nil
            settings.autoBackupDirectoryBookmark = nil
            settings.updatedAt = .now
            autoBackupDirectoryPath = nil
            try settingsRepository.save()

            if autoBackupEnabled {
                let backupURL = try backupService.createAutomaticBackupIfEnabled()
                feedbackMessage = backupURL.map { "Папка резервных копий сброшена на значение по умолчанию. Создана резервная копия: \($0.path)" }
                    ?? "Папка резервных копий сброшена на значение по умолчанию."
            } else {
                feedbackMessage = "Папка резервных копий сброшена на значение по умолчанию."
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func createTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Введите название тега."
            feedbackMessage = nil
            return
        }

        do {
            let normalizedName = TagRepository.normalizedName(for: trimmedName)

            if try tagRepository.fetchByNormalizedName(normalizedName) != nil {
                errorMessage = "Тег с таким названием уже существует."
                feedbackMessage = nil
                return
            }

            try tagRepository.insert(Tag(name: trimmedName))
            newTagName = ""
            tags = try tagRepository.fetchAll()
            appEnvironment.notifyDataChanged()
            feedbackMessage = "Тег создан."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func renameTag(_ tag: Tag, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Название тега не может быть пустым."
            feedbackMessage = nil
            return
        }

        let currentNormalizedName = TagRepository.normalizedName(for: tag.name)
        let newNormalizedName = TagRepository.normalizedName(for: trimmedName)

        guard currentNormalizedName != newNormalizedName else {
            if tag.name != trimmedName {
                tag.name = trimmedName
                tag.updatedAt = .now
                try? tagRepository.save()
                tags = (try? tagRepository.fetchAll()) ?? tags
            }
            return
        }

        do {
            if let existingTag = try tagRepository.fetchByNormalizedName(newNormalizedName),
               existingTag.id != tag.id {
                errorMessage = "Тег с таким названием уже существует."
                feedbackMessage = nil
                return
            }

            let sessions = try sessionRepository.fetchAll()
            for session in sessions where session.tags.contains(tag.name) {
                session.tags = session.tags.map { $0 == tag.name ? trimmedName : $0 }.orderedUnique()
                session.updatedAt = .now
            }

            tag.name = trimmedName
            tag.updatedAt = .now
            try sessionRepository.save()
            try tagRepository.save()
            tags = try tagRepository.fetchAll()
            appEnvironment.notifyDataChanged()
            feedbackMessage = "Тег обновлён."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }

    func deleteTag(_ tag: Tag) {
        do {
            let sessions = try sessionRepository.fetchAll()
            for session in sessions where session.tags.contains(tag.name) {
                session.tags.removeAll { $0 == tag.name }
                session.updatedAt = .now
            }

            try sessionRepository.save()
            try tagRepository.delete(tag)
            tags = try tagRepository.fetchAll()
            appEnvironment.notifyDataChanged()
            feedbackMessage = "Тег удалён."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            feedbackMessage = nil
        }
    }
}

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case timer
    case tags
    case data
    case appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "Основные"
        case .timer:
            return "Таймер"
        case .tags:
            return "Теги"
        case .data:
            return "Данные"
        case .appearance:
            return "Внешний вид"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Базовые параметры учёта и локали"
        case .timer:
            return "Поведение таймера, напоминания и округление"
        case .tags:
            return "Управление тегами и быстрым поиском"
        case .data:
            return "Экспорт, импорт и автобэкапы"
        case .appearance:
            return "Тема приложения и визуальные эффекты"
        }
    }

    var iconName: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .timer:
            return "timer"
        case .tags:
            return "tag"
        case .data:
            return "externaldrive"
        case .appearance:
            return "sparkles"
        }
    }
}

private extension Array where Element: Hashable {
    func orderedUnique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
