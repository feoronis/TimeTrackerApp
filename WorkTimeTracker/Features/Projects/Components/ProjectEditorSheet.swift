import SwiftUI

struct ProjectEditorSheet: View {
    @Binding var draft: ProjectDraft
    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(isEditing ? "Редактирование проекта" : "Новый проект")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Название", text: $draft.name)
                TextField("HEX-цвет", text: $draft.colorHex)
                TextField("Символ SF Symbols", text: $draft.iconName)
                TextField("Ставка в час", text: $draft.hourlyRateText)

                TextField(
                    "Заметки",
                    text: $draft.notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
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
        .frame(width: 440)
    }
}
