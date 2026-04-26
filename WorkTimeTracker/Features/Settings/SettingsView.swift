import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsScene()
    }
}

private struct SettingsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        SettingsContentView(appEnvironment: appEnvironment)
    }
}

private struct SettingsContentView: View {
    @State private var viewModel: SettingsViewModel
    @State private var isPresented = false

    init(appEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: SettingsViewModel(appEnvironment: appEnvironment))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: AppSpacing.xl) {
                SettingsSidebar(viewModel: viewModel)
                    .frame(width: 256)

                SettingsDetailPanel(viewModel: viewModel)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 12)
        }
        .background(AppColors.windowBackground)
        .clearFocusOnTap()
        .onChange(of: viewModel.defaultHourlyRateText, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.currencyCode, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.timeFormat, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.firstDayOfWeek, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.roundingMode, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.roundingMinutes, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.longTimerReminderMinutes, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.autoBackupEnabled, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.themeMode, initial: false) { viewModel.saveSettingsSilently() }
        .onChange(of: viewModel.liquidGlassEnabled, initial: false) { viewModel.saveSettingsSilently() }
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
    }
}

private struct SettingsSidebar: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Настройки")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Персонализация приложения, таймера и сохранности данных")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    ForEach(SettingsSection.allCases) { section in
                        Button {
                            withAnimation(.snappy(duration: 0.34, extraBounce: 0.02)) {
                                viewModel.selectedSection = section
                            }
                        } label: {
                            SettingsSidebarItem(
                                section: section,
                                isSelected: viewModel.selectedSection == section
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct SettingsSidebarItem: View {
    let section: SettingsSection
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? AppColors.inverseText : AppColors.secondaryText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.inverseText : AppColors.primaryText)

                Text(section.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.8) : AppColors.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Color.white.opacity(0.14) : AppColors.solidControlBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isSelected ? 1 : 0.995)
        .animation(.smooth(duration: 0.24), value: isSelected)
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(AppColors.primaryActionFill)
        }

        return AnyShapeStyle(AppColors.tileFill)
    }
}

private struct SettingsDetailPanel: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            SettingsHeaderCard(viewModel: viewModel)

            if let errorMessage = viewModel.errorMessage {
                SettingsMessageBanner(text: errorMessage, tint: AppColors.errorText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else if let feedbackMessage = viewModel.feedbackMessage {
                SettingsMessageBanner(text: feedbackMessage, tint: AppColors.successText)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Group {
                switch viewModel.selectedSection {
                case .general:
                    SettingsOverviewSection(viewModel: viewModel)
                case .timer:
                    SettingsTimerOnlySection(viewModel: viewModel)
                case .tags:
                    SettingsTagsSection(viewModel: viewModel)
                case .data:
                    SettingsDataOnlySection(viewModel: viewModel)
                case .appearance:
                    SettingsAppearanceOnlySection(viewModel: viewModel)
                }
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.smooth(duration: 0.30), value: viewModel.selectedSection)
        .animation(.smooth(duration: 0.24), value: viewModel.tags.map(\.id))
    }
}

private struct SettingsHeaderCard: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.selectedSection.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text(viewModel.selectedSection.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                HStack(spacing: 12) {
                    SettingsQuickStatus(title: "Валюта", value: viewModel.currencyCode)
                    SettingsQuickStatus(title: "Тема", value: viewModel.themeMode.title)
                }
            }
        }
    }
}

private struct SettingsQuickStatus: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppColors.tileBorder, lineWidth: 1)
        }
    }
}

private struct SettingsMessageBanner: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct SettingsOverviewSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            SettingsGeneralSection(viewModel: viewModel)
            SettingsTimerOnlySection(viewModel: viewModel)
            SettingsDataOnlySection(viewModel: viewModel)
            SettingsAppearanceOnlySection(viewModel: viewModel)
            SettingsTagsSection(viewModel: viewModel)
        }
    }
}

private struct SettingsGeneralSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsCard(
            title: "Основные параметры",
            subtitle: "Ставка по умолчанию, валюта и правила отображения времени"
        ) {
            HStack(alignment: .top, spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SettingsTextField(title: "Ставка по умолчанию") {
                        TextField("", text: $viewModel.defaultHourlyRateText.digitsOnly())
                            .textFieldStyle(.plain)
                    }

                    SettingsMenuField(title: "Валюта", selectionText: currencyTitle(for: viewModel.currencyCode)) {
                        currencyButton("RUB", title: "Российский рубль (₽)", viewModel: viewModel)
                        currencyButton("USD", title: "Доллар США ($)", viewModel: viewModel)
                        currencyButton("EUR", title: "Евро (€)", viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    SettingsMenuField(title: "Формат времени", selectionText: viewModel.timeFormat.title) {
                        ForEach(TimeFormatOption.allCases) { option in
                            Button(option.title) { viewModel.timeFormat = option }
                        }
                    }

                    SettingsMenuField(title: "Первый день недели", selectionText: viewModel.firstDayOfWeek.title) {
                        ForEach(FirstDayOfWeekOption.allCases) { option in
                            Button(option.title) { viewModel.firstDayOfWeek = option }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private func currencyTitle(for code: String) -> String {
        switch code {
        case "USD":
            return "Доллар США ($)"
        case "EUR":
            return "Евро (€)"
        default:
            return "Российский рубль (₽)"
        }
    }

    private func currencyButton(_ code: String, title: String, viewModel: SettingsViewModel) -> some View {
        Button(title) {
            viewModel.currencyCode = code
        }
    }
}

private struct SettingsTimerOnlySection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsCard(
            title: "Таймер и расчёты",
            subtitle: "Округление, напоминания и поведение трекинга"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    SettingsMenuField(title: "Напоминание о длинном таймере", selectionText: reminderTitle(for: viewModel.longTimerReminderMinutes)) {
                        ForEach(viewModel.reminderOptions, id: \.self) { value in
                            Button(reminderTitle(for: value)) {
                                viewModel.longTimerReminderMinutes = value
                            }
                        }
                    }

                    SettingsMenuField(title: "Режим округления", selectionText: viewModel.roundingMode.title) {
                        ForEach(RoundingModeOption.allCases) { option in
                            Button(option.title) { viewModel.roundingMode = option }
                        }
                    }
                }

                HStack(alignment: .top, spacing: AppSpacing.xl) {
                    SettingsNumberAdjustField(
                        title: "Минуты округления",
                        suffix: "мин",
                        value: $viewModel.roundingMinutes,
                        range: 0...120
                    )

                    SettingsInfoTile(
                        title: "Один активный таймер",
                        description: "В приложении одновременно может работать только одна активная сессия."
                    )
                }

                SettingsToggleTile(
                    title: "Автоматические резервные копии",
                    subtitle: "Полный JSON-снимок создаётся автоматически после изменений данных",
                    isOn: $viewModel.autoBackupEnabled
                )
            }
        }
    }

    private func reminderTitle(for value: Int) -> String {
        "Каждые \(value) минут"
    }
}

private struct SettingsDataOnlySection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsCard(
            title: "Данные и перенос",
            subtitle: "Экспорт, импорт и резервное копирование без потери существующих записей"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Импорт работает в merge-режиме: существующие записи сохраняются, а дубликаты по UUID не добавляются повторно.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                SettingsInfoTile(
                    title: "Папка автобэкапов",
                    description: viewModel.autoBackupLocationText
                )

                HStack(spacing: AppSpacing.md) {
                    Button("Выбрать папку") {
                        viewModel.selectAutoBackupFolder()
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())

                    Button("По умолчанию") {
                        viewModel.resetAutoBackupFolder()
                    }
                    .buttonStyle(SettingsSecondaryButtonStyle())
                }

                Text("По умолчанию копии сохраняются в \(viewModel.defaultAutoBackupLocationText). В папке хранится не больше 20 резервных копий: при создании новой самые старые удаляются автоматически.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 2), spacing: AppSpacing.lg) {
                    SettingsActionTile(title: "Экспорт JSON", subtitle: "Полный слепок данных приложения", icon: "square.and.arrow.up.on.square") {
                        viewModel.exportJSONActionMessage()
                    }

                    SettingsActionTile(title: "Импорт JSON", subtitle: "Объединение данных из резервной копии", icon: "square.and.arrow.down.on.square") {
                        viewModel.importJSONActionMessage()
                    }

                    SettingsActionTile(title: "Экспорт CSV", subtitle: "Табличный экспорт для внешней аналитики", icon: "tablecells") {
                        viewModel.exportCSVActionMessage()
                    }

                    SettingsActionTile(title: "Резервная копия", subtitle: "Быстрое локальное сохранение состояния", icon: "externaldrive.badge.plus") {
                        viewModel.backupActionMessage()
                    }
                }
            }
        }
    }
}

private struct SettingsTagsSection: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var editingTagID: UUID?
    @State private var editedTagName = ""
    @State private var tagPendingDeletion: Tag?

    var body: some View {
        SettingsCard(
            title: "Теги",
            subtitle: "Быстрые метки для сессий, календаря и отчётов"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack(alignment: .bottom, spacing: AppSpacing.md) {
                    SettingsTextField(title: "Новый тег") {
                        TextField("", text: $viewModel.newTagName)
                            .textFieldStyle(.plain)
                    }

                    Button("Создать") {
                        withAnimation(.smooth(duration: 0.24)) {
                            viewModel.createTag()
                        }
                    }
                    .buttonStyle(SettingsPrimaryButtonStyle())
                }

                if viewModel.tags.isEmpty {
                    Text("Теги ещё не созданы.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.tags) { tag in
                            SettingsTagRow(
                                tag: tag,
                                isEditing: editingTagID == tag.id,
                                editedTagName: $editedTagName,
                                onEdit: {
                                    withAnimation(.smooth(duration: 0.24)) {
                                        editingTagID = tag.id
                                        editedTagName = tag.name
                                    }
                                },
                                onCancel: {
                                    withAnimation(.smooth(duration: 0.24)) {
                                        editingTagID = nil
                                        editedTagName = ""
                                    }
                                },
                                onSave: {
                                    withAnimation(.smooth(duration: 0.24)) {
                                        viewModel.renameTag(tag, to: editedTagName)
                                        editingTagID = nil
                                        editedTagName = ""
                                    }
                                },
                                onDelete: {
                                    tagPendingDeletion = tag
                                }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
        }
        .alert(
            "Удалить тег?",
            isPresented: Binding(
                get: { tagPendingDeletion != nil },
                set: { if $0 == false { tagPendingDeletion = nil } }
            ),
            presenting: tagPendingDeletion
        ) { tag in
            Button("Удалить", role: .destructive) {
                withAnimation(.smooth(duration: 0.24)) {
                    viewModel.deleteTag(tag)
                    tagPendingDeletion = nil
                }
            }

            Button("Отмена", role: .cancel) {
                tagPendingDeletion = nil
            }
        } message: { tag in
            Text("Тег «\(tag.name)» будет удалён из списка и из всех сессий, где он использовался.")
        }
    }
}

private struct SettingsAppearanceOnlySection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsCard(
            title: "Внешний вид",
            subtitle: "Светлая и тёмная тема, а также уровень стеклянности интерфейса"
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SettingsChoicePicker(
                    title: "Тема",
                    options: ThemeModeOption.allCases,
                    selected: viewModel.themeMode,
                    titleFor: { $0.title },
                    onSelect: { option in
                        viewModel.themeMode = option
                    }
                )

                SettingsToggleTile(
                    title: "Liquid Glass",
                    subtitle: "Более выраженные стеклянные поверхности и мягкие блики",
                    isOn: $viewModel.liquidGlassEnabled
                )

                Text("Приложение использует единый фирменный сине-фиолетовый акцент. Отдельная настройка accent color не требуется.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                }

                content
            }
        }
    }
}

private struct SettingsTextField<Content: View>: View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsMenuField<MenuContent: View>: View {
    let title: String
    let selectionText: String
    let menuContent: MenuContent

    init(title: String, selectionText: String, @ViewBuilder content: () -> MenuContent) {
        self.title = title
        self.selectionText = selectionText
        self.menuContent = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Menu {
                menuContent
            } label: {
                HStack(spacing: 10) {
                    Text(selectionText)
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsChoicePicker<Option: Identifiable & Hashable>: View {
    let title: String
    let options: [Option]
    let selected: Option
    let titleFor: (Option) -> String
    let onSelect: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                ForEach(options) { option in
                    let isSelected = option == selected

                    Button {
                        withAnimation(.snappy(duration: 0.22, extraBounce: 0.02)) {
                            onSelect(option)
                        }
                    } label: {
                        Text(titleFor(option))
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
        }
    }
}

private struct SettingsNumberAdjustField: View {
    let title: String
    let suffix: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 12) {
                TextField("", text: textBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(width: 64)

                Text(suffix)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    adjustButton(systemName: "chevron.up", enabled: value < range.upperBound) {
                        value = min(range.upperBound, value + 1)
                    }

                    adjustButton(systemName: "chevron.down", enabled: value > range.lowerBound) {
                        value = max(range.lowerBound, value - 1)
                    }
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
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func adjustButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(enabled ? AppColors.secondaryText : AppColors.mutedText)
                .frame(width: 22, height: 18)
                .background(AppColors.rowFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
    }
}

private struct SettingsToggleTile: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: AppColors.selectedAccent))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.tileBorder, lineWidth: 1)
        }
    }
}

private struct SettingsInfoTile: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)

            Text(description)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.tileBorder, lineWidth: 1)
        }
    }
}

private struct SettingsActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.selectedAccent)
                    .frame(width: 34, height: 34)
                    .background(AppColors.accentSoftFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.tileBorder, lineWidth: 1)
            }
        }
        .buttonStyle(SettingsActionButtonStyle())
    }
}

private struct SettingsTagRow: View {
    let tag: Tag
    let isEditing: Bool
    @Binding var editedTagName: String
    let onEdit: () -> Void
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                SettingsTextField(title: "Название") {
                    TextField("", text: $editedTagName)
                        .textFieldStyle(.plain)
                }

                Button("Сохранить", action: onSave)
                    .buttonStyle(SettingsPrimaryButtonStyle())

                Button("Отмена", action: onCancel)
                    .buttonStyle(SettingsSecondaryButtonStyle())
            } else {
                TagChip(title: tag.name, color: AppColors.blue)

                Spacer()

                Button("Изменить", action: onEdit)
                    .buttonStyle(SettingsSecondaryButtonStyle())

                Button("Удалить", action: onDelete)
                    .buttonStyle(SettingsDestructiveButtonStyle())
            }
        }
        .padding(14)
        .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColors.tileBorder, lineWidth: 1)
        }
    }
}

private struct SettingsPrimaryButtonStyle: ButtonStyle {
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

private struct SettingsSecondaryButtonStyle: ButtonStyle {
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
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SettingsDestructiveButtonStyle: ButtonStyle {
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
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SettingsActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
