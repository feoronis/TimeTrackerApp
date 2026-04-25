import SwiftUI

struct SettingsBehaviorCard: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Поведение таймера и расчетов")
                    .font(.headline)

                Picker("Режим округления", selection: $viewModel.roundingMode) {
                    ForEach(RoundingModeOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Stepper(
                    "Минуты округления: \(viewModel.roundingMinutes)",
                    value: $viewModel.roundingMinutes,
                    in: 0...120
                )

                Stepper(
                    "Напоминание о длинном таймере: \(viewModel.longTimerReminderMinutes) мин.",
                    value: $viewModel.longTimerReminderMinutes,
                    in: 0...720
                )

                Toggle("Включить синхронизацию через iCloud", isOn: $viewModel.iCloudSyncEnabled)
                Toggle("Автоматические резервные копии", isOn: $viewModel.autoBackupEnabled)

                Text(viewModel.cloudSyncStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
