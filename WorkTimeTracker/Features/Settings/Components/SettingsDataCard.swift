import SwiftUI

struct SettingsDataCard: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Данные и перенос")
                    .font(.headline)

                Text("Экспорт и импорт работают в merge-режиме: существующие записи не удаляются, а дубликаты по UUID пропускаются.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: AppSpacing.md) {
                    Button("Экспорт JSON") {
                        viewModel.exportJSONActionMessage()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())

                    Button("Импорт JSON") {
                        viewModel.importJSONActionMessage()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                }

                HStack(spacing: AppSpacing.md) {
                    Button("Экспорт CSV") {
                        viewModel.exportCSVActionMessage()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())

                    Button("Создать резервную копию") {
                        viewModel.backupActionMessage()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                }
            }
        }
    }
}
