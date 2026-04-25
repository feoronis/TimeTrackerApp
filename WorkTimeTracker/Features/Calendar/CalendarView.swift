import SwiftUI

struct CalendarView: View {
    var body: some View {
        CalendarScene()
    }
}

private struct CalendarScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        CalendarContentView(appEnvironment: appEnvironment)
    }
}

private struct CalendarContentView: View {
    @State private var viewModel: CalendarViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: CalendarViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Calendar")
                    .font(.system(size: 32, weight: .semibold))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    CalendarSidebarCard(viewModel: viewModel)
                        .frame(minWidth: 720, maxWidth: .infinity)

                    CalendarDetailsPanel(viewModel: viewModel)
                        .frame(width: 420)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, AppSpacing.xxl)
        }
        .task {
            viewModel.load()
        }
    }
}
