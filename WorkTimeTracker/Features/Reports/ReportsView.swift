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
    @State private var isPresented = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: ReportsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Отчёты")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.errorText)
                }

                ReportPeriodPicker(viewModel: viewModel)
                ReportSummaryCards(viewModel: viewModel)
                ReportCharts(viewModel: viewModel)
                ReportsProjectsTable(viewModel: viewModel)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 12)
        }
        .clearFocusOnTap()
        .background(AppColors.windowBackground)
        .task {
            viewModel.load()
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.36)) {
                isPresented = true
            }
        }
        .onDisappear {
            isPresented = false
        }
    }
}
