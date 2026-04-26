import SwiftUI

struct SessionsView: View {
    var body: some View {
        SessionsScene()
    }
}

private struct SessionsScene: View {
    @Environment(AppEnvironment.self) private var appEnvironment

    var body: some View {
        SessionsContentView(appEnvironment: appEnvironment, sharedAppEnvironment: appEnvironment)
    }
}

private struct SessionsContentView: View {
    @State private var viewModel: SessionsViewModel
    @State private var isPresented = false
    let sharedAppEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment, sharedAppEnvironment: AppEnvironment) {
        _viewModel = State(initialValue: SessionsViewModel(appEnvironment: appEnvironment))
        self.sharedAppEnvironment = sharedAppEnvironment
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                HStack {
                    Text("Сессии")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Spacer()

                    Button {
                        viewModel.presentCreateSheet()
                    } label: {
                        Label("Новая сессия", systemImage: "plus")
                    }
                    .buttonStyle(CreateSessionButtonStyle())
                }

                SessionsFiltersBar(viewModel: viewModel)
                SessionsSummaryCards(viewModel: viewModel)
                SessionsTable(viewModel: viewModel)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(AppColors.errorText)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 12)
        }
        .background(AppColors.windowBackground)
        .clearFocusOnTap()
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
                },
                onDelete: viewModel.editingSession == nil ? nil : {
                    guard let editingSession = viewModel.editingSession else { return }
                    viewModel.isEditorPresented = false
                    viewModel.requestDelete(editingSession)
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
        .onAppear {
            withAnimation(.smooth(duration: 0.36)) {
                isPresented = true
            }
        }
        .onDisappear {
            isPresented = false
        }
        .onChange(of: sharedAppEnvironment.dataChangeToken) {
            viewModel.load()
        }
    }
}

private struct SessionsFiltersBar: View {
    @Bindable var viewModel: SessionsViewModel

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            SessionsPeriodModePicker(viewModel: viewModel)

            if viewModel.dateSelectionMode == .month {
                SessionsMonthControl(viewModel: viewModel)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                DateRangeField(startDate: $viewModel.startDate, endDate: $viewModel.endDate)
                    .onChange(of: viewModel.startDate, initial: false) { _, newValue in
                        viewModel.updateCustomStartDate(newValue)
                    }
                    .onChange(of: viewModel.endDate, initial: false) { _, newValue in
                        viewModel.updateCustomEndDate(newValue)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            SessionsMenuFilter(
                title: viewModel.projects.first(where: { $0.id == viewModel.selectedProjectID })?.name ?? "Все проекты"
            ) {
                Button("Все проекты") {
                    viewModel.selectedProjectID = nil
                    viewModel.selectPage(1)
                }

                ForEach(viewModel.projects, id: \.id) { project in
                    Button(project.name) {
                        viewModel.selectedProjectID = project.id
                        viewModel.selectPage(1)
                    }
                }
            }

            SessionsMenuFilter(
                title: viewModel.selectedTag ?? "Все теги"
            ) {
                Button("Все теги") {
                    viewModel.selectedTag = nil
                    viewModel.selectPage(1)
                }

                ForEach(viewModel.availableTags, id: \.self) { tag in
                    Button(tag) {
                        viewModel.selectedTag = tag
                        viewModel.selectPage(1)
                    }
                }
            }

            Button {
                withAnimation(.smooth(duration: 0.28)) {
                    viewModel.resetFilters()
                }
            } label: {
                Label("Сбросить", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(FilterResetButtonStyle())

            Spacer()
        }
        .animation(.smooth(duration: 0.28), value: viewModel.dateSelectionMode == .month)
    }
}

private struct SessionsPeriodModePicker: View {
    @Bindable var viewModel: SessionsViewModel

    var body: some View {
        HStack(spacing: 8) {
            Button("Месяц") {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.02)) {
                    viewModel.activateMonthMode()
                }
            }
            .buttonStyle(SessionsFilterToggleButtonStyle(isActive: viewModel.dateSelectionMode == .month))

            Button("Период") {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.02)) {
                    viewModel.activateCustomMode()
                }
            }
            .buttonStyle(SessionsFilterToggleButtonStyle(isActive: viewModel.dateSelectionMode == .custom))
        }
    }
}

private struct SessionsMonthControl: View {
    @Bindable var viewModel: SessionsViewModel

    var body: some View {
        HStack(spacing: 6) {
            monthStepButton(systemName: "chevron.left") {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.02)) {
                    viewModel.selectPreviousMonth()
                }
            }

            Menu {
                ForEach(viewModel.monthOptions) { option in
                    Button(option.title) {
                        withAnimation(.snappy(duration: 0.32, extraBounce: 0.02)) {
                            viewModel.selectMonth(option.date)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.monthTitle)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(minWidth: 170)
            }
            .buttonStyle(.plain)

            monthStepButton(systemName: "chevron.right") {
                withAnimation(.snappy(duration: 0.32, extraBounce: 0.02)) {
                    viewModel.selectNextMonth()
                }
            }
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(AppColors.primaryText)
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
        }
    }

    private func monthStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SessionsMenuFilter<MenuContent: View>: View {
    let title: String
    let menuContent: MenuContent

    init(title: String, @ViewBuilder content: () -> MenuContent) {
        self.title = title
        self.menuContent = content()
    }

    var body: some View {
        Menu {
            menuContent
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SessionsSummaryCards: View {
    @Bindable var viewModel: SessionsViewModel

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 4),
            spacing: AppSpacing.lg
        ) {
            ForEach(viewModel.summaryCards) { item in
                SessionsSummaryCard(item: item)
            }
        }
    }
}

private struct SessionsSummaryCard: View {
    let item: SessionSummaryCardItem
    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(item.accentColor)

                Text(item.value)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                HStack(alignment: .center, spacing: AppSpacing.xs) {
                    Image(systemName: item.trendDirection.symbolName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(trendColor)

                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(trendColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            AppBundleIcon(
                name: item.iconAssetName,
                size: 55,
                color: item.accentColor,
                rendersAsTemplate: false
            )
            .frame(width: 55, height: 55, alignment: .topTrailing)
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(item.backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(item.borderColor, lineWidth: 1.2)
        }
        .scaleEffect(isVisible ? 1 : 0.985)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .contentTransition(.interpolate)
        .animation(.smooth(duration: 0.30), value: item.value)
        .onAppear {
            withAnimation(.smooth(duration: 0.30)) {
                isVisible = true
            }
        }
        .onChange(of: item.value) {
            withAnimation(.smooth(duration: 0.26)) {
                isVisible = true
            }
        }
    }

    private var trendColor: Color {
        switch item.trendDirection {
        case .up:
            return item.accentColor
        case .down:
            return AppColors.errorText
        case .neutral:
            return AppColors.secondaryText
        }
    }
}

private struct SessionsTable: View {
    @Bindable var viewModel: SessionsViewModel
    @State private var animateRows = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SessionsTableHeader()

                if viewModel.pagedSessions.isEmpty {
                    EmptyStateView(
                        title: "Сессии не найдены",
                        message: "Измените фильтры или создайте новую сессию.",
                        systemImage: "clock.badge.exclamationmark"
                    )
                    .frame(minHeight: 220)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.pagedSessions.enumerated()), id: \.element.id) { index, session in
                            SessionsRow(
                                session: session,
                                currencyCode: viewModel.currencyCode,
                                rateText: viewModel.rateText(for: session),
                                incomeText: viewModel.incomeText(for: session),
                                onEdit: { viewModel.presentEditSheet(for: session) },
                                onDelete: { viewModel.requestDelete(session) }
                            )
                            .padding(.top, index == 0 ? 0 : 0)
                            .transition(.move(edge: .top).combined(with: .opacity))

                            if session.id != viewModel.pagedSessions.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(AppColors.tileFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.smooth(duration: 0.28), value: viewModel.currentPage)
                    .animation(.smooth(duration: 0.28), value: viewModel.pagedSessions.map(\.id))
                }

                HStack {
                    Text(viewModel.pageDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(1...min(viewModel.totalPages, 5), id: \.self) { page in
                            Button("\(page)") {
                                withAnimation(.snappy(duration: 0.28, extraBounce: 0.01)) {
                                    viewModel.selectPage(page)
                                }
                            }
                            .buttonStyle(SessionPageButtonStyle(isActive: viewModel.currentPage == page))
                        }
                    }
                }
            }
        }
        .opacity(animateRows ? 1 : 0)
        .offset(y: animateRows ? 0 : 10)
        .onAppear {
            withAnimation(.smooth(duration: 0.34)) {
                animateRows = true
            }
        }
        .onChange(of: viewModel.pagedSessions.map(\.id)) {
            withAnimation(.smooth(duration: 0.28)) {
                animateRows = true
            }
        }
    }
}

private struct SessionsTableHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Дата").frame(width: 108, alignment: .leading)
            Text("Проект").frame(width: 228, alignment: .leading)
            Text("Старт").frame(width: 60, alignment: .leading)
            Text("Конец").frame(width: 60, alignment: .leading)
            Text("Время").frame(width: 84, alignment: .trailing)
            Text("Ставка").frame(width: 110, alignment: .trailing)
            Text("Сумма").frame(width: 110, alignment: .trailing)
            Text("Теги").frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 28, height: 1)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColors.secondaryText)
        .padding(.horizontal, 16)
    }
}

private struct SessionsRow: View {
    let session: WorkSession
    let currencyCode: String
    let rateText: String
    let incomeText: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(AppFormatters.reportShortDateText(session.startTime))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 108, alignment: .leading)

            HStack(spacing: 8) {
                ProjectDot(colorHex: session.project?.colorHex ?? "#7C5CFF", size: 12)
                Text(session.project?.name ?? "Без проекта")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(width: 228, alignment: .leading)

            Text(AppFormatters.statusTimeText(session.startTime))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 60, alignment: .leading)

            Text(session.endTime.map(AppFormatters.statusTimeText) ?? "—")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 60, alignment: .leading)

            Text(AppFormatters.compactDurationText(from: session.durationSeconds))
                .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 84, alignment: .trailing)

            Text(rateText)
                .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 110, alignment: .trailing)

            Text(incomeText)
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 110, alignment: .trailing)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(session.tags, id: \.self) { tag in
                        TagChip(title: tag, color: tagColor(tag))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button("Редактировать", action: onEdit)
                Button("Удалить", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(width: 28)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    private func tagColor(_ tag: String) -> Color {
        switch tag {
        case "Frontend":
            return AppColors.purple
        case "UI/UX":
            return AppColors.blue
        case "WordPress":
            return AppColors.green
        case "Клиент":
            return AppColors.yellow
        default:
            return AppColors.blue
        }
    }
}

private struct CreateSessionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.inverseText)
            .padding(.horizontal, 18)
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

private struct SessionsFilterToggleButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? AppColors.inverseText : AppColors.secondaryText)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                isActive
                ? AnyShapeStyle(AppColors.primaryActionFill.opacity(configuration.isPressed ? 0.86 : 1))
                : AnyShapeStyle(AppColors.fieldFill)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isActive ? Color.white.opacity(AppearancePreferences.isDarkMode ? 0.14 : 0.5) : AppColors.fieldBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct FilterResetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColors.secondaryText)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SessionPageButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(isActive ? AppColors.inverseText : AppColors.secondaryText)
            .frame(width: 30, height: 30)
            .background(
                isActive ? AppColors.selectedAccent : AppColors.fieldFill,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isActive ? AppColors.accentBorder : AppColors.fieldBorder, lineWidth: 1)
            }
    }
}
