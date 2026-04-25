import SwiftUI

struct ReportPeriodPicker: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Период и фильтры")
                    .font(.headline)

                HStack(alignment: .bottom, spacing: AppSpacing.lg) {
                    Picker("Период", selection: $viewModel.filter.period) {
                        ForEach(ReportPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .frame(maxWidth: 240)

                    Picker("Проект", selection: $viewModel.filter.projectID) {
                        Text("Все проекты").tag(Optional<UUID>.none)

                        ForEach(viewModel.projects, id: \.id) { project in
                            Text(project.name).tag(Optional(project.id))
                        }
                    }
                    .frame(maxWidth: 240)

                    Picker("Тег", selection: $viewModel.filter.tag) {
                        Text("Все теги").tag(Optional<String>.none)

                        ForEach(viewModel.report?.availableTags ?? [], id: \.self) { tag in
                            Text(tag).tag(Optional(tag))
                        }
                    }
                    .frame(maxWidth: 220)
                }

                if viewModel.filter.period == .custom {
                    HStack(spacing: AppSpacing.lg) {
                        DatePicker(
                            "С",
                            selection: $viewModel.filter.customStartDate,
                            displayedComponents: [.date]
                        )

                        DatePicker(
                            "По",
                            selection: $viewModel.filter.customEndDate,
                            displayedComponents: [.date]
                        )
                    }
                }

                Button("Применить фильтры") {
                    viewModel.applyFilters()
                }
                .buttonStyle(GlassPrimaryButtonStyle())
            }
        }
    }
}
