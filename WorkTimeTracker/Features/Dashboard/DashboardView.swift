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
            sharedAppEnvironment: appEnvironment,
            onShowAllSessions: onShowAllSessions
        )
    }
}

private struct DashboardContentView: View {
    @State private var viewModel: DashboardViewModel
    @State private var isPresented = false
    let sharedAppEnvironment: AppEnvironment
    let onShowAllSessions: (() -> Void)?

    init(appEnvironment: AppEnvironment, sharedAppEnvironment: AppEnvironment, onShowAllSessions: (() -> Void)?) {
        _viewModel = State(initialValue: DashboardViewModel(appEnvironment: appEnvironment))
        self.sharedAppEnvironment = sharedAppEnvironment
        self.onShowAllSessions = onShowAllSessions
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { proxy in
            let contentWidth = max(proxy.size.width - 80, 0)
            let isCompact = contentWidth < 1_040

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    Text("Панель")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(AppColors.errorText)
                    }

                    TimerControlCard(viewModel: viewModel, availableWidth: contentWidth)

                    DashboardNoteSection(text: $viewModel.sessionNote)
                    DashboardTagsSection(viewModel: viewModel)

                    DashboardSummaryCards(viewModel: viewModel, availableWidth: contentWidth)

                    RecentSessionsCard(
                        sessions: viewModel.recentSessions,
                        currencyCode: viewModel.currencyCode,
                        onShowAllSessions: onShowAllSessions,
                        isCompact: isCompact
                    )
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
        .onChange(of: sharedAppEnvironment.dataChangeToken) {
            viewModel.reloadData()
        }
    }
}

private struct DashboardNoteSection: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Заметка")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            TextField("Работаю над главной страницей и адаптивом", text: $text)
                .textFieldStyle(.plain)
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.fieldFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
                .shadow(color: AppColors.glassShadow.opacity(0.5), radius: 8, y: 3)
        }
    }
}

private struct DashboardTagsSection: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Теги")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                        viewModel.presentCreateTag()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(AppColors.secondaryText)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppColors.controlBackground)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(AppColors.separator, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, AppSpacing.sm)
        .sheet(isPresented: $viewModel.isCreateTagPresented) {
            CreateTagSheet(
                title: $viewModel.newTagName,
                onCancel: { viewModel.isCreateTagPresented = false },
                onCreate: viewModel.createTag
            )
        }
    }
}

private struct CreateTagSheet: View {
    @Binding var title: String
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Новый тег")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.primaryText)

            TextField("Название", text: $title)
                .textFieldStyle(.plain)
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }

            HStack {
                Spacer()
                Button("Отменить", action: onCancel)
                    .buttonStyle(GlassSecondaryButtonStyle())
                Button("Создать", action: onCreate)
                    .buttonStyle(GlassPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xl)
        .frame(width: 320)
    }
}
