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
    let timerService: TimerService
    let sessionCalculator: SessionCalculator
    let reportService: ReportService
    let backupService: BackupService
    let exportService: ExportService
    let importService: ImportService
    let notificationService: NotificationService
    let cloudSyncStatusService: CloudSyncStatusService
    private(set) var bootstrapErrorMessage: String?
    private var hasBootstrapped = false

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        let modelContext = modelContainer.mainContext

        projectRepository = ProjectRepository(modelContext: modelContext)
        sessionRepository = SessionRepository(modelContext: modelContext)
        settingsRepository = SettingsRepository(modelContext: modelContext)
        dayNoteRepository = DayNoteRepository(modelContext: modelContext)

        sessionCalculator = SessionCalculator()
        timerService = TimerService(
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            sessionCalculator: sessionCalculator
        )
        reportService = ReportService(sessionCalculator: sessionCalculator)
        exportService = ExportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository,
            sessionCalculator: sessionCalculator
        )
        backupService = BackupService(exportService: exportService)
        importService = ImportService(
            projectRepository: projectRepository,
            sessionRepository: sessionRepository,
            settingsRepository: settingsRepository,
            dayNoteRepository: dayNoteRepository
        )
        notificationService = NotificationService()
        cloudSyncStatusService = CloudSyncStatusService()
    }

    func bootstrap() {
        guard hasBootstrapped == false else { return }

        do {
            _ = try settingsRepository.fetchOrCreateSettings()
            try timerService.restoreActiveSessionIfNeeded()
            bootstrapErrorMessage = nil
            hasBootstrapped = true
        } catch {
            bootstrapErrorMessage = error.localizedDescription
        }
    }
}
