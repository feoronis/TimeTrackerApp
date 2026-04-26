import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AppEnvironment {
    let modelContainer: ModelContainer
    let projectRepository: ProjectRepository
    let sessionRepository: SessionRepository
    let settingsRepository: SettingsRepository
    let dayNoteRepository: DayNoteRepository
    let tagRepository: TagRepository
    let timerService: TimerService
    let sessionCalculator: SessionCalculator
    let reportService: ReportService
    let backupService: BackupService
    let exportService: ExportService
    let importService: ImportService
    let projectPasswordService: ProjectPasswordService
    let notificationService: NotificationService
    let cloudSyncStatusService: CloudSyncStatusService
    private(set) var dataChangeToken = UUID()
    private(set) var bootstrapErrorMessage: String?
    private var hasBootstrapped = false
    private var automaticBackupTask: Task<Void, Never>?

    init(
        modelContainer: ModelContainer,
        cloudSyncStartupState: CloudSyncStartupState = CloudSyncStartupState(mode: .localOnly),
        projectPasswordService: ProjectPasswordService? = nil
    ) {
        self.modelContainer = modelContainer

        let modelContext = modelContainer.mainContext

        projectRepository = ProjectRepository(modelContext: modelContext)
        sessionRepository = SessionRepository(modelContext: modelContext)
        settingsRepository = SettingsRepository(modelContext: modelContext)
        dayNoteRepository = DayNoteRepository(modelContext: modelContext)
        tagRepository = TagRepository(modelContext: modelContext)

        sessionCalculator = SessionCalculator()
        timerService = TimerService(
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            sessionCalculator: sessionCalculator
        )
        reportService = ReportService(sessionCalculator: sessionCalculator)
        self.projectPasswordService = projectPasswordService ?? ProjectPasswordService()
        exportService = ExportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            tagRepository: tagRepository,
            sessionCalculator: sessionCalculator
        )
        backupService = BackupService(
            exportService: exportService,
            settingsRepository: settingsRepository
        )
        importService = ImportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            tagRepository: tagRepository
        )
        notificationService = NotificationService()
        cloudSyncStatusService = CloudSyncStatusService(startupState: cloudSyncStartupState)
    }

    func bootstrap() {
        guard hasBootstrapped == false else { return }

        do {
            let settings = try settingsRepository.fetchOrCreateSettings()
            syncAppearancePreferences(from: settings)
            try timerService.restoreActiveSessionIfNeeded()
            try tagRepository.upsertMissingTags(named: sessionRepository.fetchAll().flatMap(\.tags))
            bootstrapErrorMessage = nil
            hasBootstrapped = true
        } catch {
            bootstrapErrorMessage = error.localizedDescription
        }
    }

    func syncAppearancePreferences(from settings: AppSettings) {
        UserDefaults.standard.set(settings.themeMode, forKey: AppearancePreferences.themeModeKey)
        UserDefaults.standard.set(settings.liquidGlassEnabled, forKey: AppearancePreferences.liquidGlassEnabledKey)
        UserDefaults.standard.set(settings.timeFormat, forKey: AppearancePreferences.timeFormatKey)
        UserDefaults.standard.set(settings.firstDayOfWeek, forKey: AppearancePreferences.firstDayOfWeekKey)
        CloudSyncPreferences.setEnabled(settings.iCloudSyncEnabled)
    }

    func notifyDataChanged() {
        dataChangeToken = UUID()
        scheduleAutomaticBackup()
    }

    private func scheduleAutomaticBackup() {
        automaticBackupTask?.cancel()
        automaticBackupTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }

            _ = try? backupService.createAutomaticBackupIfEnabled()
        }
    }
}
