import SwiftUI

struct ProjectsView: View {
    var body: some View {
        ProjectsScene()
    }
}

private struct ProjectsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        ProjectsContentView(appEnvironment: appEnvironment)
    }
}

private struct ProjectsContentView: View {
    @State private var viewModel: ProjectsViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: ProjectsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text("Проекты")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Spacer()

                Toggle("Показывать архив", isOn: $viewModel.showArchived)
                    .toggleStyle(.switch)

                Button("Новый проект") {
                    viewModel.presentCreateSheet()
                }
                .buttonStyle(GlassPrimaryButtonStyle())
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            GlassCard {
                if viewModel.visibleProjects.isEmpty {
                    EmptyStateView(
                        title: "Проектов пока нет",
                        message: "Создайте первый проект, чтобы запускать таймер и вести сессии.",
                        systemImage: "folder.badge.plus"
                    )
                    .frame(minHeight: 240)
                } else {
                    List(viewModel.visibleProjects) { project in
                        ProjectRowView(project: project)
                            .contextMenu {
                                Button("Редактировать") {
                                    viewModel.presentEditSheet(for: project)
                                }

                                if project.isArchived {
                                    Button("Вернуть из архива") {
                                        viewModel.unarchive(project)
                                    }
                                } else {
                                    Button("В архив") {
                                        viewModel.archive(project)
                                    }
                                }
                            }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .frame(minHeight: 320)
                }
            }
        }
        .padding(AppSpacing.xxl)
        .sheet(isPresented: $viewModel.isEditorPresented) {
            ProjectEditorSheet(
                draft: $viewModel.editorDraft,
                isEditing: viewModel.editingProject != nil,
                onCancel: {
                    viewModel.isEditorPresented = false
                },
                onSave: {
                    viewModel.saveProject()
                }
            )
        }
        .task {
            viewModel.load()
        }
    }
}
