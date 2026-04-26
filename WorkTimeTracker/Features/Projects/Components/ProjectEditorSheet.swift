import SwiftUI

struct ProjectEditorSheet: View {
    @Binding var draft: ProjectDraft
    let isEditing: Bool
    let colorOptions: [String]
    let iconOptions: [String]
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: (() -> Void)?
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Text(isEditing ? "Редактирование проекта" : "Создать проект")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(alignment: .top, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ProjectFormField(title: "Название проекта") {
                        TextField("", text: $draft.name)
                            .textFieldStyle(.plain)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    ProjectColorPicker(draft: $draft, colorOptions: colorOptions)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    ProjectIconPicker(draft: $draft, iconOptions: iconOptions)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ProjectFormField(title: "Ставка") {
                        TextField("", text: $draft.hourlyRateText.digitsOnly())
                            .textFieldStyle(.plain)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    ProjectStatusPicker(isArchived: $draft.isArchived)
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                    ProjectNotesField(text: $draft.notes)
                        .frame(maxHeight: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .animation(.smooth(duration: 0.24), value: draft.colorHex)
            .animation(.smooth(duration: 0.24), value: draft.iconName)
            .animation(.smooth(duration: 0.24), value: draft.isArchived)

            HStack {
                if let onDelete, isEditing {
                    Button("Удалить", role: .destructive, action: onDelete)
                        .buttonStyle(ProjectSheetDeleteButtonStyle())
                }

                Spacer()

                Button("Отмена", action: onCancel)
                    .buttonStyle(ProjectSheetSecondaryButtonStyle())

                Button(isEditing ? "Сохранить" : "Создать проект", action: onSave)
                    .buttonStyle(ProjectSheetPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 720)
        .background(AppColors.windowBackground)
        .opacity(isPresented ? 1 : 0)
        .offset(y: isPresented ? 0 : 10)
        .onAppear {
            withAnimation(.smooth(duration: 0.30)) {
                isPresented = true
            }
        }
        .onDisappear {
            isPresented = false
        }
    }
}

private struct ProjectFormField<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            content
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
        }
    }
}

private struct ProjectSheetPrimaryButtonStyle: ButtonStyle {
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

private struct ProjectSheetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }
    }
}

private struct ProjectSheetDeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.errorText)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.errorText.opacity(0.24), lineWidth: 1)
            }
    }
}

private struct ProjectColorPicker: View {
    @Binding var draft: ProjectDraft
    let colorOptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Выбор цвета")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                ForEach(colorOptions, id: \.self) { colorHex in
                    Button {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                            draft.colorHex = colorHex
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: colorHex) ?? AppColors.purple)
                            .frame(width: 24, height: 24)
                            .overlay {
                                if draft.colorHex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.inverseText)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        draft.colorHex == colorHex ? AppColors.accentBorder : AppColors.solidControlBorder,
                                        lineWidth: draft.colorHex == colorHex ? 2 : 1
                                    )
                                    .padding(-4)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ProjectIconPicker: View {
    @Binding var draft: ProjectDraft
    let iconOptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Иконка проекта")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(iconOptions, id: \.self) { iconName in
                    Button {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                            draft.iconName = iconName
                        }
                    } label: {
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(draft.iconName == iconName ? AppColors.selectedAccent : AppColors.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        draft.iconName == iconName ? AppColors.accentBorder : AppColors.solidControlBorder,
                                        lineWidth: draft.iconName == iconName ? 2 : 1
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ProjectStatusPicker: View {
    @Binding var isArchived: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Статус проекта")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                statusButton(title: "Активный", isSelected: isArchived == false) {
                    isArchived = false
                }
                statusButton(title: "Архив", isSelected: isArchived) {
                    isArchived = true
                }
            }
        }
    }

    private func statusButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? AppColors.selectedAccent : AppColors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? AppColors.accentBorder : AppColors.solidControlBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectNotesField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Заметка")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            TextEditor(text: $text)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 190)
                .padding(12)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
        }
    }
}
