import SwiftUI

struct SessionEditorSheet: View {
    @Binding var draft: SessionDraft
    let projects: [Project]
    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(isEditing ? "Редактирование сессии" : "Новая сессия")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                Picker("Проект", selection: $draft.projectID) {
                    Text("Без проекта").tag(Optional<UUID>.none)

                    ForEach(projects, id: \.id) { project in
                        Text(project.name).tag(Optional(project.id))
                    }
                }

                DatePicker(
                    "Начало",
                    selection: $draft.startTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                DatePicker(
                    "Окончание",
                    selection: $draft.endTime,
                    displayedComponents: [.date, .hourAndMinute]
                )

                TextField("Заметка", text: $draft.note, axis: .vertical)
                    .lineLimit(2...5)

                TextField("Теги через запятую", text: $draft.tagsText)
                TextField("Своя ставка", text: $draft.customHourlyRateText)

                if draft.endTime < draft.startTime {
                    Text("Окончание не может быть раньше начала.")
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("Отмена", action: onCancel)
                    .buttonStyle(GlassSecondaryButtonStyle())

                Button("Сохранить", action: onSave)
                    .buttonStyle(GlassPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppSpacing.xl)
        .frame(width: 460)
    }
}
