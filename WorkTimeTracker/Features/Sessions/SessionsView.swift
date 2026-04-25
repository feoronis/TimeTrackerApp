import SwiftUI

struct SessionsView: View {
    var body: some View {
        SessionsScene()
    }
}

private struct SessionsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        SessionsContentView(appEnvironment: appEnvironment)
    }
}

private struct SessionsContentView: View {
    @State private var viewModel: SessionsViewModel

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: SessionsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            HStack {
                Text("Сессии")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Spacer()

                Button("Новая сессия") {
                    viewModel.presentCreateSheet()
                }
                .buttonStyle(GlassPrimaryButtonStyle())

                Button("Обновить") {
                    viewModel.load()
                }
                .buttonStyle(GlassSecondaryButtonStyle())
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            GlassCard {
                if viewModel.sessions.isEmpty {
                    EmptyStateView(
                        title: "Сессий пока нет",
                        message: "Здесь появятся завершенные или вручную добавленные сессии.",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                    )
                    .frame(minHeight: 240)
                } else {
                    List(viewModel.sessions) { session in
                        let isCompletedSession = session.endTime != nil

                        SessionListRow(
                            session: session,
                            rateText: viewModel.rateText(for: session),
                            incomeText: viewModel.incomeText(for: session)
                        )
                        .contextMenu {
                            Button("Редактировать") {
                                viewModel.presentEditSheet(for: session)
                            }
                            .disabled(isCompletedSession == false)

                            Button("Дублировать") {
                                viewModel.duplicate(session)
                            }
                            .disabled(isCompletedSession == false)

                            Button("Удалить") {
                                viewModel.requestDelete(session)
                            }
                            .disabled(isCompletedSession == false)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .frame(minHeight: 320)
                }
            }
        }
        .padding(AppSpacing.xxl)
        .sheet(isPresented: $viewModel.isEditorPresented) {
            SessionEditorSheet(
                draft: $viewModel.draft,
                projects: viewModel.projects,
                isEditing: viewModel.editingSession != nil,
                onCancel: {
                    viewModel.isEditorPresented = false
                },
                onSave: {
                    viewModel.saveDraft()
                }
            )
        }
        .alert("Удалить сессию?", isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button("Удалить", role: .destructive) {
                viewModel.deletePendingSession()
            }

            Button("Отмена", role: .cancel) {
                viewModel.sessionPendingDeletion = nil
            }
        } message: {
            Text("Это действие нельзя отменить автоматически.")
        }
        .task {
            viewModel.load()
        }
    }
}
