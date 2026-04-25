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

                Picker("Акцентный цвет", selection: $viewModel.accentColor) {
                    ForEach(AccentColorOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle("Режим Liquid Glass", isOn: $viewModel.liquidGlassEnabled)

                Text("Визуальные настройки сохраняются уже сейчас, а более глубокое применение к теме и акцентам можно будет расширять дальше без переделки модели.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
