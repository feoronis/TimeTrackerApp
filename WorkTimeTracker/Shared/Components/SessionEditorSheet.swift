import SwiftUI

struct SessionEditorSheet: View {
    @Binding var draft: SessionDraft
    let projects: [Project]
    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: (() -> Void)?
    @State private var isPresented = false

    private var availableProjects: [Project] {
        projects.filter { project in
            project.isArchived == false || project.id == draft.projectID
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Text(isEditing ? "Редактирование сессии" : "Новая сессия")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(alignment: .top, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SessionModePicker(mode: $draft.mode)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    SessionProjectPicker(
                        title: "Проект",
                        selection: $draft.projectID,
                        projects: availableProjects
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    SessionTimeSection(draft: $draft)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                .frame(width: 344, alignment: .leading)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SessionNotesField(text: $draft.note)
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                    SessionFormField(title: "Теги") {
                        TextField("", text: $draft.tagsText)
                            .textFieldStyle(.plain)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    SessionFormField(title: "Своя ставка") {
                        TextField("", text: $draft.customHourlyRateText.digitsOnly())
                            .textFieldStyle(.plain)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    SessionFormField(title: "Фиксированная сумма") {
                        TextField("", text: $draft.fixedIncomeAmountText.digitsOnly())
                            .textFieldStyle(.plain)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    if draft.fixedIncomeAmountText.isEmpty == false {
                        Text("Если указана фиксированная сумма, доход сессии считается по ней, а не по ставке.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                            .padding(.horizontal, 2)
                            .transition(.opacity)
                    }

                    if draft.mode == .timedInterval && draft.endTime < draft.startTime {
                        Text("Окончание не может быть раньше начала.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.errorText)
                            .padding(.horizontal, 2)
                            .transition(.opacity)
                    }
                }
                .frame(width: 344, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.smooth(duration: 0.24), value: draft.mode)
            .animation(.smooth(duration: 0.24), value: draft.fixedIncomeAmountText.isEmpty)

            HStack {
                if let onDelete, isEditing {
                    Button("Удалить", role: .destructive, action: onDelete)
                        .buttonStyle(SessionSheetDeleteButtonStyle())
                }

                Spacer()

                Button("Отмена", action: onCancel)
                    .buttonStyle(SessionSheetSecondaryButtonStyle())

                Button(isEditing ? "Сохранить" : "Создать сессию", action: onSave)
                    .buttonStyle(SessionSheetPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 760)
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

private struct SessionTimeSection: View {
    @Binding var draft: SessionDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if draft.mode == .timedInterval {
                SessionDateField(title: "Начало", selection: $draft.startTime, components: [.date, .hourAndMinute])
                SessionDateField(title: "Окончание", selection: $draft.endTime, components: [.date, .hourAndMinute])
            } else {
                SessionDateField(title: "Дата выполнения", selection: $draft.completedAt, components: [.date, .hourAndMinute])

                SessionDurationField(draft: $draft)
            }
        }
    }
}

private struct SessionDateField: View {
    let title: String
    @Binding var selection: Date
    let components: DatePickerComponents
    @State private var isPopoverPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: AppSpacing.sm) {
                Text(AppFormatters.editableDateText(selection))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if components.contains(.hourAndMinute) {
                    Text(AppFormatters.statusTimeText(selection))
                        .foregroundStyle(AppColors.secondaryText)
                }

                Button {
                    isPopoverPresented.toggle()
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(AppColors.secondaryText)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isPopoverPresented) {
                    VStack(spacing: AppSpacing.md) {
                        DatePicker(
                            "Дата",
                            selection: $selection,
                            displayedComponents: .date
                        )

                        if components.contains(.hourAndMinute) {
                            DatePicker(
                                "Время",
                                selection: $selection,
                                displayedComponents: .hourAndMinute
                            )
                        }
                    }
                    .padding()
                    .frame(width: 300)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
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

private struct SessionModePicker: View {
    @Binding var mode: SessionDraftMode

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Тип")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                modeButton(title: "Интервал", value: .timedInterval)
                modeButton(title: "Задача", value: .completedTask)
            }
        }
    }

    private func modeButton(title: String, value: SessionDraftMode) -> some View {
        let isSelected = mode == value

        return Button {
            withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                mode = value
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

private struct SessionProjectPicker: View {
    let title: String
    @Binding var selection: UUID?
    let projects: [Project]

    private var selectedTitle: String {
        projects.first(where: { $0.id == selection })?.name ?? "Без проекта"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Menu {
                Button("Без проекта") {
                    selection = nil
                }

                ForEach(projects, id: \.id) { project in
                    Button(project.name) {
                        selection = project.id
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(selectedTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)

                    Spacer(minLength: 10)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct SessionDurationField: View {
    @Binding var draft: SessionDraft

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Длительность")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                SessionDurationUnitField(
                    title: "Часы",
                    suffix: "ч",
                    value: $draft.durationHours,
                    range: 0...999
                )

                SessionDurationUnitField(
                    title: "Минуты",
                    suffix: "м",
                    value: $draft.durationMinutes,
                    range: 0...59
                )
            }
        }
    }
}

private struct SessionDurationUnitField: View {
    let title: String
    let suffix: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(1)

            HStack(spacing: 12) {
                TextField("", text: textBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(width: 58)

                Text(suffix)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    durationButton(systemName: "chevron.up") {
                        value = min(range.upperBound, value + 1)
                    }
                    .disabled(value >= range.upperBound)

                    durationButton(systemName: "chevron.down") {
                        value = max(range.lowerBound, value - 1)
                    }
                    .disabled(value <= range.lowerBound)
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }
        }
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { "\(value)" },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                guard digits.isEmpty == false else {
                    value = range.lowerBound
                    return
                }

                if let parsed = Int(digits) {
                    value = min(range.upperBound, max(range.lowerBound, parsed))
                }
            }
        )
    }

    private func durationButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 22, height: 18)
                .background(AppColors.rowFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SessionNotesField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Заметка")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            TextField("", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(minHeight: 136, alignment: .topLeading)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
        }
    }
}

private struct SessionControlField<Content: View>: View {
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
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
        }
    }
}

private typealias SessionFormField = SessionControlField

private struct SessionSheetPrimaryButtonStyle: ButtonStyle {
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

private struct SessionSheetSecondaryButtonStyle: ButtonStyle {
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

private struct SessionSheetDeleteButtonStyle: ButtonStyle {
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
