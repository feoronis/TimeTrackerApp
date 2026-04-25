import SwiftUI

struct ReportsView: View {
    var body: some View {
        ReportsScene()
    }
}

private struct ReportsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        ReportsContentView(appEnvironment: appEnvironment)
    }
}

private struct ReportsContentView: View {
    @State private var viewModel: ReportsViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: ReportsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Отчеты")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                ReportPeriodPicker(viewModel: viewModel)
                ReportSummaryCards(viewModel: viewModel)
                ReportCharts(viewModel: viewModel)

                ExpandableProjectReportList(
                    title: "Проекты за период",
                    projectRows: viewModel.report?.projectRows ?? [],
                    currencyCode: viewModel.currencyCode,
                    expandedProjectIDs: $viewModel.expandedProjectIDs
                )
            }
            .padding(AppSpacing.xxl)
        }
        .task {
            viewModel.load()
        }
    }
}
