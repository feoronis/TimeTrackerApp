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
    @State private var isPresented = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: CalendarViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - 80, 0)
            let isCompact = contentWidth < 1_120
            let isVeryCompact = contentWidth < 980

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text("Календарь")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(AppColors.errorText)
                    }

                    Group {
                        if isVeryCompact {
                            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                                CalendarSidebarCard(viewModel: viewModel, availableWidth: contentWidth)
                                CalendarDetailsPanel(viewModel: viewModel, isCompact: true)
                            }
                        } else {
                            HStack(alignment: .top, spacing: isCompact ? AppSpacing.lg : AppSpacing.xl) {
                                CalendarSidebarCard(viewModel: viewModel, availableWidth: max(contentWidth - (isCompact ? 360 : 420), 0))
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ZStack(alignment: .topTrailing) {
                                    CalendarDetailsPanel(viewModel: viewModel, isCompact: isCompact)
                                }
                                .frame(width: isCompact ? 340 : 420, alignment: .trailing)
                                .layoutPriority(1)
                            }
                        }
                    }
                }
                .padding(.horizontal, isCompact ? 24 : 40)
                .padding(.vertical, AppSpacing.xxl)
                .opacity(isPresented ? 1 : 0)
                .offset(y: isPresented ? 0 : 12)
            }
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
