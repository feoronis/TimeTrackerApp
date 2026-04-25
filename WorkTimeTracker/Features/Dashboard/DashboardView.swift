import SwiftUI

struct DashboardView: View {
    var onShowAllSessions: (() -> Void)?

    var body: some View {
        DashboardScene(onShowAllSessions: onShowAllSessions)
    }
}

private struct DashboardScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    let onShowAllSessions: (() -> Void)?

    var body: some View {
        DashboardContentView(
            appEnvironment: appEnvironment,
            onShowAllSessions: onShowAllSessions
        )
    }
}

private struct DashboardContentView: View {
    @State private var viewModel: DashboardViewModel
    let onShowAllSessions: (() -> Void)?

    init(appEnvironment: AppEnvironment, onShowAllSessions: (() -> Void)?) {
        _viewModel = State(initialValue: DashboardViewModel(appEnvironment: appEnvironment))
        self.onShowAllSessions = onShowAllSessions
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Dashboard")
                    .font(.system(size: 32, weight: .semibold))

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }

                TimerControlCard(viewModel: viewModel)

                DashboardNoteSection(text: $viewModel.sessionNote)
                DashboardTagsSection(viewModel: viewModel)

                DashboardSummaryCards(viewModel: viewModel)

                RecentSessionsCard(
                    sessions: viewModel.recentSessions,
                    currencyCode: viewModel.currencyCode,
                    onShowAllSessions: onShowAllSessions
                )
            }
            .padding(.horizontal, 40)
            .padding(.vertical, AppSpacing.xxl)
        }
        .task {
            viewModel.load()
        }
    }
}

private struct DashboardNoteSection: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Заметка")
                .font(.headline)

            TextField("Быстрый контекст текущей работы", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, 14)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppColors.glassHighlight.opacity(0.28), lineWidth: 1)
                }
        }
    }
}

private struct DashboardTagsSection: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Теги")
                .font(.headline)

            HStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.suggestedTags) { tag in
                    Button {
                        viewModel.toggleTag(tag.title)
                    } label: {
                        TagChip(
                            title: tag.title,
                            color: Color(hex: tag.colorHex) ?? AppColors.accent,
                            isSelected: tag.isSelected
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    viewModel.tagsText = viewModel.tagsText.trimmingCharacters(in: .whitespacesAndNewlines)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(AppColors.glassHighlight.opacity(0.28), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            TextField("Теги через запятую", text: $viewModel.tagsText)
                .textFieldStyle(.roundedBorder)
        }
    }
}
