import SwiftUI

struct ProjectsView: View {
    var body: some View {
        ProjectsScene()
    }
}

private struct ProjectsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        ProjectsContentView(appEnvironment: appEnvironment, sharedAppEnvironment: appEnvironment)
    }
}

private struct ProjectsContentView: View {
    @State private var viewModel: ProjectsViewModel
    let sharedAppEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment, sharedAppEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: ProjectsViewModel(appEnvironment: appEnvironment))
        self.sharedAppEnvironment = sharedAppEnvironment
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xl) {
            projectListPanel
                .frame(minWidth: 320, idealWidth: 370, maxWidth: 390)

            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 4)
                .layoutPriority(1)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clearFocusOnTap()
        .background(AppColors.windowBackground)
        .task {
            viewModel.load()
        }
        .onChange(of: sharedAppEnvironment.dataChangeToken) {
            viewModel.load()
        }
    }

    private var projectListPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Проекты")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Структурируйте рабочие пространства, настройки и доступы по каждому проекту.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)

                    Button {
                        viewModel.presentCreateDetail()
                    } label: {
                        Label("Новый проект", systemImage: "plus")
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(width: 16, alignment: .leading)

                    TextField("Поиск проектов", text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    ))
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.errorText)
                }

                if viewModel.visibleRows.isEmpty {
                    EmptyStateView(
                        title: "Проекты не найдены",
                        message: "Измените запрос или создайте новый проект.",
                        systemImage: "folder.badge.questionmark"
                    )
                    .frame(minHeight: 300)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(viewModel.visibleRows) { row in
                                ProjectRowView(
                                    row: row,
                                    currencyCode: viewModel.currencyCode,
                                    isSelected: viewModel.selectedProjectID == row.id,
                                    onSelect: {
                                        viewModel.selectProject(row.id)
                                    },
                                    onArchiveToggle: {
                                        guard let project = viewModel.projects.first(where: { $0.id == row.id }) else {
                                            return
                                        }

                                        row.isArchived ? viewModel.unarchive(project) : viewModel.archive(project)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        switch viewModel.destination {
        case .create:
            ProjectDetailView(
                appEnvironment: sharedAppEnvironment,
                project: nil,
                selectedTab: viewModel.selectedDetailTab,
                onSelectedTabChange: { selectedTab in
                    viewModel.selectedDetailTab = selectedTab
                },
                onProjectSaved: { projectID in
                    viewModel.handleProjectSaved(projectID: projectID)
                },
                onProjectDeleted: { _ in }
            )
            .id("project-create")
        case let .project(projectID):
            if let project = viewModel.projects.first(where: { $0.id == projectID }) {
                ProjectDetailView(
                    appEnvironment: sharedAppEnvironment,
                    project: project,
                    selectedTab: viewModel.selectedDetailTab,
                    onSelectedTabChange: { selectedTab in
                        viewModel.selectedDetailTab = selectedTab
                    },
                    onProjectSaved: { savedProjectID in
                        viewModel.handleProjectSaved(projectID: savedProjectID)
                    },
                    onProjectDeleted: { deletedProjectID in
                        viewModel.handleProjectDeleted(projectID: deletedProjectID)
                    }
                )
                .id("project-\(projectID.uuidString)")
            } else {
                placeholderDetail
            }
        case nil:
            placeholderDetail
        }
    }

    private var placeholderDetail: some View {
        GlassCard {
            EmptyStateView(
                title: "Выберите проект",
                message: "Откройте проект слева, чтобы настроить его данные и хранить пароли внутри одной детальной страницы.",
                systemImage: "rectangle.on.rectangle"
            )
            .frame(minHeight: 540)
        }
    }

}
