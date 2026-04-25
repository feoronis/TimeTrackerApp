import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsScene()
    }
}

private struct SettingsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        SettingsContentView(appEnvironment: appEnvironment)
    }
}

private struct SettingsContentView: View {
    @State private var viewModel: SettingsViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: SettingsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Настройки")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if let feedbackMessage = viewModel.feedbackMessage {
                    Text(feedbackMessage)
                        .foregroundStyle(.secondary)
                }

                SettingsGeneralCard(viewModel: viewModel)
                SettingsBehaviorCard(viewModel: viewModel)
                SettingsAppearanceCard(viewModel: viewModel)
                SettingsDataCard(viewModel: viewModel)

                HStack {
                    Spacer()

                    Button("Сохранить настройки") {
                        viewModel.saveSettings()
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
            }
            .padding(AppSpacing.xxl)
        }
        .task {
            viewModel.load()
        }
    }
}
