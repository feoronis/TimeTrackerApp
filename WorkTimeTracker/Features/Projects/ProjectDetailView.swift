import SwiftUI

struct ProjectDetailView: View {
    @State private var viewModel: ProjectDetailViewModel
    private let onProjectSaved: (UUID) -> Void
    private let onProjectDeleted: (UUID) -> Void
    private let onSelectedTabChange: (ProjectDetailTab) -> Void

    init(
        appEnvironment: AppEnvironment,
        project: Project?,
        selectedTab: ProjectDetailTab = .general,
        onSelectedTabChange: @escaping (ProjectDetailTab) -> Void = { _ in },
        onProjectSaved: @escaping (UUID) -> Void,
        onProjectDeleted: @escaping (UUID) -> Void
    ) {
        _viewModel = State(initialValue: ProjectDetailViewModel(
            appEnvironment: appEnvironment,
            project: project,
            selectedTab: selectedTab
        ))
        self.onSelectedTabChange = onSelectedTabChange
        self.onProjectSaved = onProjectSaved
        self.onProjectDeleted = onProjectDeleted
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                header
                ProjectDetailTabs(selectedTab: Binding(
                    get: { viewModel.selectedTab },
                    set: { viewModel.selectedTab = $0 }
                ))

                if let errorMessage = viewModel.errorMessage {
                    BannerMessageView(message: errorMessage, tint: AppColors.errorText)
                }

                if let successMessage = viewModel.successMessage {
                    BannerMessageView(message: successMessage, tint: AppColors.successText)
                }

                ZStack {
                    Group {
                        switch viewModel.selectedTab {
                        case .general:
                            ProjectGeneralTab(
                                draft: Binding(
                                    get: { viewModel.draft },
                                    set: { viewModel.draft = $0 }
                                ),
                                colorOptions: viewModel.colorOptions,
                                iconOptions: viewModel.iconOptions,
                                currencyCode: viewModel.currencyCode
                            )
                        case .passwords:
                            ProjectPasswordsTab(viewModel: viewModel)
                        }
                    }
                    .id(contentAnimationToken)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 54, y: 0)),
                            removal: .opacity.combined(with: .offset(x: -40, y: 0))
                        )
                    )
                }
                .animation(.snappy(duration: 0.34, extraBounce: 0.02), value: contentAnimationToken)
            }
            .frame(maxWidth: 980, alignment: .leading)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isPasswordEditorPresented },
            set: { viewModel.isPasswordEditorPresented = $0 }
        )) {
            ProjectPasswordEditorSheet(
                draft: Binding(
                    get: { viewModel.passwordEditorDraft },
                    set: { viewModel.passwordEditorDraft = $0 }
                ),
                existingGroups: viewModel.existingGroupNames,
                isEditing: viewModel.editingPasswordID != nil,
                onCancel: {
                    viewModel.isPasswordEditorPresented = false
                },
                onSave: {
                    viewModel.savePassword()
                }
            )
        }
        .alert("Удалить проект?", isPresented: Binding(
            get: { viewModel.isDeleteConfirmationPresented },
            set: { viewModel.isDeleteConfirmationPresented = $0 }
        )) {
            Button("Удалить", role: .destructive) {
                if let deletedProjectID = viewModel.deleteProject() {
                    onProjectDeleted(deletedProjectID)
                }
            }

            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Вместе с проектом будут удалены все связанные сессии и сохранённые записи паролей.")
        }
        .alert("Удалить запись пароля?", isPresented: Binding(
            get: { viewModel.isPasswordDeleteConfirmationPresented },
            set: { viewModel.isPasswordDeleteConfirmationPresented = $0 }
        )) {
            Button("Удалить", role: .destructive) {
                viewModel.deletePendingPassword()
            }

            Button("Отмена", role: .cancel) {
                viewModel.passwordPendingDeletion = nil
            }
        } message: {
            Text("Запись будет удалена из защищённого хранилища проекта.")
        }
        .task {
            viewModel.load()
        }
        .onChange(of: viewModel.selectedTab) { _, selectedTab in
            onSelectedTabChange(selectedTab)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(viewModel.isEditingExistingProject ? "Детали проекта" : "Новый проект")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(headerSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: 560, alignment: .leading)
            }

            HStack(spacing: AppSpacing.md) {
                if viewModel.isEditingExistingProject {
                    Button("Удалить", role: .destructive) {
                        viewModel.isDeleteConfirmationPresented = true
                    }
                    .buttonStyle(GlassDestructiveButtonStyle())
                }

                Button(viewModel.isEditingExistingProject ? "Сохранить" : "Создать проект") {
                    if let projectID = viewModel.saveProject() {
                        onProjectSaved(projectID)
                    }
                }
                .buttonStyle(GlassPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var headerSubtitle: String {
        if let project = viewModel.project {
            return "Настройте свойства проекта и храните рабочие доступы внутри защищённой вкладки."
                + (project.isArchived ? " Проект находится в архиве." : "")
        }

        return "Создайте новый проект, затем при необходимости добавьте внутри него защищённые пароли."
    }

    private var contentAnimationToken: String {
        viewModel.selectedTab.rawValue
    }
}

private struct ProjectDetailTabs: View {
    @Binding var selectedTab: ProjectDetailTab

    init(selectedTab: Binding<ProjectDetailTab>) {
        _selectedTab = selectedTab
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(ProjectDetailTab.allCases) { tab in
                    Button {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 13, weight: .semibold))

                            Text(tab.title)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(selectedTab == tab ? AppColors.inverseText : AppColors.primaryText)
                        .padding(.horizontal, 16)
                        .frame(height: 42)
                        .background(background(for: tab))
                        .clipShape(Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .strokeBorder(selectedTab == tab ? Color.white.opacity(0.16) : AppColors.fieldBorder, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func background(for tab: ProjectDetailTab) -> some ShapeStyle {
        if selectedTab == tab {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.blue, AppColors.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(AppColors.fieldFill)
    }
}

private struct ProjectGeneralTab: View {
    @Binding var draft: ProjectDraft
    let colorOptions: [String]
    let iconOptions: [String]
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ProjectFormField(title: "Название проекта") {
                    TextField("Например, TimeTrack macOS", text: $draft.name)
                        .textFieldStyle(.plain)
                }

                ProjectColorPicker(draft: $draft.colorHex, colorOptions: colorOptions)
                ProjectIconPicker(draft: $draft.iconName, iconOptions: iconOptions)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ProjectFormField(title: "Ставка") {
                    TextField("0", text: $draft.hourlyRateText)
                        .textFieldStyle(.plain)
                }

                if draft.hourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    Text("Используется для расчётов сессий и отображается как \(currencyCode)/ч.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }

                ProjectStatusPicker(isArchived: $draft.isArchived)
                ProjectNotesField(text: $draft.notes)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct ProjectPasswordsTab: View {
    let viewModel: ProjectDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Пароли проекта")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Записи хранятся отдельно от данных трекера, а обычный экспорт и бэкапы их не включают.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                HStack(spacing: AppSpacing.md) {
                    Button {
                        viewModel.exportPasswords()
                    } label: {
                        Label("Экспортировать", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                    .disabled(viewModel.projectID == nil || viewModel.passwordItems.isEmpty)

                    Button {
                        viewModel.presentCreatePasswordEditor()
                    } label: {
                        Label("Добавить запись", systemImage: "plus")
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
                .fixedSize()
            }

            Text("Группируйте записи по типу доступа: прод, IMAP, CRM, админка и другие.")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.mutedText)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: 16, alignment: .leading)

                TextField("Поиск по названию или группе", text: Binding(
                    get: { viewModel.passwordSearchText },
                    set: { viewModel.passwordSearchText = $0 }
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

            if viewModel.existingGroupNames.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        groupFilterTag(title: "Все", isSelected: viewModel.selectedGroupFilter == nil) {
                            viewModel.toggleGroupFilter(nil)
                        }

                        ForEach(viewModel.existingGroupNames, id: \.self) { groupName in
                            groupFilterTag(
                                title: groupName,
                                isSelected: viewModel.selectedGroupFilter == groupName
                            ) {
                                viewModel.toggleGroupFilter(groupName)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if viewModel.projectID == nil {
                EmptyStateView(
                    title: "Сохраните проект",
                    message: "Сначала создайте проект, затем можно будет добавлять пароли и группировать их.",
                    systemImage: "lock.badge.plus"
                )
                .frame(minHeight: 360)
            } else if viewModel.groupedPasswords.isEmpty {
                EmptyStateView(
                    title: "Паролей пока нет",
                    message: "Добавьте первую запись, чтобы хранить пароли проекта внутри защищённого хранилища macOS.",
                    systemImage: "key.viewfinder"
                )
                .frame(minHeight: 360)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        ForEach(viewModel.groupedPasswords) { section in
                            VStack(alignment: .leading, spacing: AppSpacing.md) {
                                HStack {
                                    Text(section.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.primaryText)

                                    Spacer()

                                    Text("\(section.items.count)")
                                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                        .foregroundStyle(AppColors.secondaryText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(AppColors.fieldFill, in: Capsule())
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 420), spacing: AppSpacing.lg)], spacing: AppSpacing.lg) {
                                    ForEach(section.items) { item in
                                        ProjectPasswordCard(
                                            item: item,
                                            isPasswordVisible: viewModel.isPasswordVisible(item.id),
                                            onToggleVisibility: {
                                                viewModel.togglePasswordVisibility(for: item.id)
                                            },
                                            onEdit: {
                                                viewModel.presentEditPasswordEditor(item)
                                            },
                                            onDelete: {
                                                viewModel.requestDeletePassword(item)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func groupFilterTag(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? AppColors.inverseText : AppColors.primaryText)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(
                    isSelected
                        ? AnyShapeStyle(LinearGradient(
                            colors: [AppColors.blue, AppColors.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(AppColors.fieldFill)
                )
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.2) : AppColors.fieldBorder,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectPasswordCard: View {
    let item: ProjectPasswordItem
    let isPasswordVisible: Bool
    let onToggleVisibility: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false
    @State private var isDescriptionExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                Spacer()

                Menu {
                    Button("Редактировать", action: onEdit)
                    Button("Удалить", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }
                .menuStyle(.borderlessButton)
            }

            HStack(spacing: AppSpacing.sm) {
                Text(isPasswordVisible ? item.password : hiddenPasswordMask)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                Spacer()

                Button(action: onToggleVisibility) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 32, height: 32)
                        .background(AppColors.fieldFill, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }

            if let description = item.itemDescription, description.isEmpty == false {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Text(isDescriptionExpanded ? "Скрыть описание" : "Показать описание")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        Image(systemName: isDescriptionExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }
                .buttonStyle(.plain)

                if isDescriptionExpanded {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(3)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(14)
        .background(AppColors.cardSecondaryFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isHovered ? AppColors.accentBorder : AppColors.cardBorder, lineWidth: 1)
        }
        .shadow(color: AppColors.glassShadow.opacity(AppearancePreferences.isDarkMode ? 0.26 : 0.10), radius: 8, y: 4)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var hiddenPasswordMask: String {
        String(repeating: "•", count: max(8, item.password.count))
    }
}

private struct ProjectPasswordEditorSheet: View {
    @Binding var draft: ProjectPasswordDraft
    let existingGroups: [String]
    let isEditing: Bool
    let onCancel: () -> Void
    let onSave: () -> Void
    @State private var isPasswordVisible = false

    init(
        draft: Binding<ProjectPasswordDraft>,
        existingGroups: [String],
        isEditing: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        _draft = draft
        self.existingGroups = existingGroups
        self.isEditing = isEditing
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            Text(isEditing ? "Редактировать запись" : "Новая запись пароля")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(alignment: .top, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ProjectFormField(title: "Название") {
                        TextField("Например, Прод-сервер", text: $draft.title)
                            .textFieldStyle(.plain)
                    }

                    ProjectFormField(title: "Группа") {
                        TextField("Например, Инфраструктура", text: $draft.groupName)
                            .textFieldStyle(.plain)
                    }

                    if existingGroups.isEmpty == false {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Существующие группы")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.secondaryText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(existingGroups, id: \.self) { groupName in
                                        Button(groupName) {
                                            draft.groupName = groupName
                                        }
                                        .buttonStyle(.plain)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.primaryText)
                                        .padding(.horizontal, 12)
                                        .frame(height: 30)
                                        .background(AppColors.fieldFill, in: Capsule())
                                        .overlay {
                                            Capsule()
                                                .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    ProjectFormField(title: "Пароль") {
                        HStack(spacing: AppSpacing.sm) {
                            if isPasswordVisible {
                                TextField("Введите пароль", text: $draft.password)
                                    .textFieldStyle(.plain)
                            } else {
                                SecureField("Введите пароль", text: $draft.password)
                                    .textFieldStyle(.plain)
                            }

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppColors.secondaryText)
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    ProjectNotesField(
                        text: $draft.itemDescription,
                        title: "Описание",
                        minHeight: 210,
                        placeholder: "Необязательная подсказка для команды или себя."
                    )
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            HStack {
                Spacer()

                Button("Отмена", action: onCancel)
                    .buttonStyle(GlassSecondaryButtonStyle())

                Button(isEditing ? "Сохранить" : "Создать", action: onSave)
                    .buttonStyle(GlassPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 760)
        .background(AppColors.windowBackground)
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
                .frame(height: 44)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
        }
    }
}

private struct ProjectColorPicker: View {
    @Binding var draft: String
    let colorOptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Цвет проекта")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                ForEach(colorOptions, id: \.self) { colorHex in
                    Button {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                            draft = colorHex
                        }
                    } label: {
                        Circle()
                            .fill(Color(hex: colorHex) ?? AppColors.purple)
                            .frame(width: 24, height: 24)
                            .overlay {
                                if draft == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(AppColors.inverseText)
                                }
                            }
                            .overlay {
                                Circle()
                                    .strokeBorder(
                                        draft == colorHex ? AppColors.accentBorder : AppColors.solidControlBorder,
                                        lineWidth: draft == colorHex ? 2 : 1
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
    @Binding var draft: String
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
                            draft = iconName
                        }
                    } label: {
                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(draft == iconName ? AppColors.selectedAccent : AppColors.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        draft == iconName ? AppColors.accentBorder : AppColors.solidControlBorder,
                                        lineWidth: draft == iconName ? 2 : 1
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
                .frame(height: 44)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
    let title: String
    let minHeight: CGFloat
    let placeholder: String?

    init(
        text: Binding<String>,
        title: String = "Заметка",
        minHeight: CGFloat = 210,
        placeholder: String? = nil
    ) {
        _text = text
        self.title = title
        self.minHeight = minHeight
        self.placeholder = placeholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            ZStack(alignment: .topLeading) {
                if text.isEmpty, let placeholder {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.mutedText)
                        .padding(.top, 18)
                        .padding(.leading, 16)
                }

                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(AppColors.primaryText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: minHeight)
                    .padding(12)
            }
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }
        }
    }
}

private struct BannerMessageView: View {
    let message: String
    let tint: Color

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(tint.opacity(AppearancePreferences.isDarkMode ? 0.14 : 0.10), in: Capsule())
    }
}
