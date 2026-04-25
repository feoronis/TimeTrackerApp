import SwiftUI

struct SettingsGeneralCard: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Основные параметры")
                    .font(.headline)

                TextField("Ставка по умолчанию", text: $viewModel.defaultHourlyRateText)

                TextField("Код валюты", text: $viewModel.currencyCode)

                Picker("Формат времени", selection: $viewModel.timeFormat) {
                    ForEach(TimeFormatOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Picker("Первый день недели", selection: $viewModel.firstDayOfWeek) {
                    ForEach(FirstDayOfWeekOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            }
        }
    }
}
