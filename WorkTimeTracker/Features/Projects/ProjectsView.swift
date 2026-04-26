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
    @State private var isPresented = false
    let sharedAppEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment, sharedAppEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: ProjectsViewModel(appEnvironment: appEnvironment))
        self.sharedAppEnvironment = sharedAppEnvironment
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Проекты")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                HStack {
                    Button {
                        viewModel.presentCreateSheet()
                    } label: {
                        Label("Создать проект", systemImage: "plus")
                    }
                    .buttonStyle(CreateProjectButtonStyle())

                    Spacer()

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.secondaryText)
                            .frame(width: 16, alignment: .leading)

                        TextField("Поиск проектов", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .frame(width: 240, height: 40)
                    .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.errorText)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        ProjectsTableHeader()

                        if viewModel.visibleRows.isEmpty {
                            EmptyStateView(
                                title: "Проекты не найдены",
                                message: "Измените поиск или создайте новый проект.",
                                systemImage: "folder.badge.plus"
                            )
                            .frame(minHeight: 220)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.visibleRows) { row in
                                    ProjectRowView(
                                        row: row,
                                        currencyCode: viewModel.currencyCode,
                                        onEdit: {
                                            if let project = viewModel.projects.first(where: { $0.id == row.id }) {
                                                viewModel.presentEditSheet(for: project)
                                            }
                                        },
                                        onArchiveToggle: {
                                            if let project = viewModel.projects.first(where: { $0.id == row.id }) {
                                                row.isArchived ? viewModel.unarchive(project) : viewModel.archive(project)
                                            }
                                        }
                                    )

                                    if row.id != viewModel.visibleRows.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 12)
        }
        .clearFocusOnTap()
        .background(AppColors.windowBackground)
        .sheet(isPresented: $viewModel.isEditorPresented) {
            ProjectEditorSheet(
                draft: $viewModel.editorDraft,
                isEditing: viewModel.editingProject != nil,
                colorOptions: viewModel.colorOptions,
                iconOptions: viewModel.iconOptions,
                onCancel: {
                    viewModel.isEditorPresented = false
                },
                onSave: {
                    viewModel.saveProject()
                },
                onDelete: viewModel.editingProject == nil ? nil : {
                    viewModel.isEditorPresented = false
                    viewModel.requestDeleteEditingProject()
                }
            )
        }
        .alert("Удалить проект?", isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button("Удалить", role: .destructive) {
                viewModel.deletePendingProject()
            }

            Button("Отмена", role: .cancel) {
                viewModel.projectPendingDeletion = nil
            }
        } message: {
            Text("Вместе с проектом будут удалены все связанные сессии. Это действие нельзя отменить автоматически.")
        }
        .onAppear {
            withAnimation(.smooth(duration: 0.36)) {
                isPresented = true
            }
        }
        .onDisappear {
            isPresented = false
        }
        .task {
            viewModel.load()
        }
        .onChange(of: sharedAppEnvironment.dataChangeToken) {
            viewModel.load()
        }
    }
}

private struct ProjectsTableHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("Название").frame(maxWidth: .infinity, alignment: .leading)
            Text("Иконка").frame(width: 70, alignment: .center)
            Text("Ставка").frame(width: 120, alignment: .trailing)
            Text("Время").frame(width: 100, alignment: .trailing)
            Text("Доход").frame(width: 120, alignment: .trailing)
            Text("Статус").frame(width: 110, alignment: .center)
            Color.clear.frame(width: 28, height: 1)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColors.secondaryText)
        .padding(.horizontal, 16)
    }
}

private struct CreateProjectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.inverseText)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(AppColors.primaryActionFill.opacity(configuration.isPressed ? 0.86 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(AppearancePreferences.isDarkMode ? 0.14 : 0.55), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
