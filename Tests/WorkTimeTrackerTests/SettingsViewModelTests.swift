import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct SettingsViewModelTests {
    @Test
    func savesUpdatedSettingsValues() throws {
        let context = try SettingsTestContext()
        let viewModel = SettingsViewModel(appEnvironment: context.environment)

        viewModel.load()
        viewModel.defaultHourlyRateText = "250"
        viewModel.currencyCode = "eur"
        viewModel.roundingMode = .nearest
        viewModel.roundingMinutes = 15
        viewModel.longTimerReminderMinutes = 90
        viewModel.iCloudSyncEnabled = true
        viewModel.autoBackupEnabled = true
        viewModel.themeMode = .dark
        viewModel.accentColor = .orange
        viewModel.liquidGlassEnabled = false

        viewModel.saveSettings()

        let settings = try context.settingsRepository.fetchOrCreateSettings()
        #expect(settings.defaultHourlyRate == Decimal(250))
        #expect(settings.currencyCode == "EUR")
        #expect(settings.roundingMode == "nearest")
        #expect(settings.roundingMinutes == 15)
        #expect(settings.longTimerReminderMinutes == 90)
        #expect(settings.iCloudSyncEnabled == true)
        #expect(settings.autoBackupEnabled == true)
        #expect(settings.themeMode == "dark")
        #expect(settings.accentColorName == "orange")
        #expect(settings.liquidGlassEnabled == false)
    }

    @Test
    func rejectsInvalidDefaultRate() throws {
        let context = try SettingsTestContext()
        let viewModel = SettingsViewModel(appEnvironment: context.environment)

        viewModel.load()
        viewModel.defaultHourlyRateText = "abc"
        viewModel.saveSettings()

        #expect(viewModel.errorMessage == "Ставка по умолчанию должна быть числом.")
    }
}

@MainActor
private struct SettingsTestContext {
    let container: ModelContainer
    let settingsRepository: SettingsRepository
    let environment: AppEnvironment

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerSettingsTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )

        container = try ModelContainer(for: schema, configurations: [configuration])
        settingsRepository = SettingsRepository(modelContext: container.mainContext)
        environment = AppEnvironment(modelContainer: container)
    }
}
