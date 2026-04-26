import SwiftUI

struct SettingsAppearanceCard: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Внешний вид")
                    .font(.headline)

                Picker("Тема", selection: $viewModel.themeMode) {
                    ForEach(ThemeModeOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle("Режим Liquid Glass", isOn: $viewModel.liquidGlassEnabled)

                Text("Приложение использует единый сине-фиолетовый glow-градиент без отдельной настройки акцентного цвета.")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}
