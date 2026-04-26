import SwiftUI

struct TimerControlCard: View {
    @Bindable var viewModel: DashboardViewModel
    let availableWidth: CGFloat
    @FocusState private var isRateFieldFocused: Bool
    @State private var isProjectListPresented = false
    @State private var isEditingRate = false
    @State private var hoverProjectID: UUID?
    @State private var rateDraft = ""

    private var activeSession: WorkSession? {
        viewModel.timerService.activeSession
    }

    private var isActive: Bool {
        activeSession != nil
    }

    private var isPaused: Bool {
        activeSession?.isPaused == true
    }

    private var isCompact: Bool {
        availableWidth < 1_020
    }

    private var isVeryCompact: Bool {
        availableWidth < 760
    }

    var body: some View {
        ZStack {
            cardBackground

            if isProjectListPresented {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.24)) {
                            isProjectListPresented = false
                        }
                    }
            }

            VStack(spacing: isCompact ? 18 : 24) {
                topBar
                    .zIndex(3)

                timerDisplay

                actionDock
            }
            .padding(.horizontal, isCompact ? 20 : 28)
            .padding(.vertical, isCompact ? 20 : 26)
        }
        .frame(minHeight: isCompact ? 236 : 276)
        .onChange(of: isRateFieldFocused) { _, isFocused in
            if isFocused == false, isEditingRate {
                finishRateEditing()
            }
        }
        .animation(.smooth(duration: 0.28), value: isActive)
        .animation(.smooth(duration: 0.28), value: isPaused)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppearancePreferences.isDarkMode
                        ? Color(hex: "#16243B")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.92 : 0.98)
                        : Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.88 : 0.94),
                        AppearancePreferences.isDarkMode
                        ? Color(hex: "#0C1428")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.94 : 0.98)
                        : Color(hex: "#F8FAFF")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.76 : 0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#6AA8FF")!.opacity(0.30),
                                Color(hex: "#8F5CF6")!.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 12)
                    .frame(width: 220, height: 220)
                    .offset(x: -34, y: -62)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#3DA8FF")!.opacity(0.18),
                                Color(hex: "#7B68FF")!.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 14)
                    .frame(width: 180, height: 180)
                    .offset(x: 26, y: 34)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(AppColors.cardBorder.opacity(AppearancePreferences.isDarkMode ? 1 : 0.92), lineWidth: 1)
            }
            .shadow(color: AppColors.strongShadow.opacity(0.95), radius: 24, y: 12)
    }

    private var topBar: some View {
        Group {
            if isVeryCompact {
                VStack(alignment: .leading, spacing: 14) {
                    headerTitle
                    VStack(alignment: .leading, spacing: 12) {
                        projectSelector
                        rateControl
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 16) {
                    headerTitle

                    Spacer(minLength: 12)

                    HStack(alignment: .top, spacing: isCompact ? 10 : 14) {
                        projectSelector
                        rateControl
                    }
                }
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Активная сессия")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(statusColor)

            Text(statusTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(statusColor.opacity(0.14), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(statusColor.opacity(0.18), lineWidth: 1)
        }
        .contentTransition(.interpolate)
    }

    private var timerDisplay: some View {
        VStack(spacing: 18) {
            timerCenterCard

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: isVeryCompact ? 1 : 3),
                spacing: 10
            ) {
                metricPill(
                    title: "Доход сессии",
                    value: viewModel.activeTimerIncomeText,
                    icon: "rublesign",
                    tint: Color(hex: "#2A8AA1")!
                )

                metricPill(
                    title: "Проект",
                    value: viewModel.selectedProject?.name ?? "Не выбран",
                    icon: "circle.fill",
                    tint: Color(hex: viewModel.selectedProject?.colorHex ?? "#6A62FB")!
                )

                metricPill(
                    title: "Ставка",
                    value: viewModel.rateFieldValueText + "/ч",
                    icon: "gauge.with.dots.needle.33percent",
                    tint: Color(hex: "#6B58D6")!
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var timerCenterCard: some View {
        VStack(spacing: 10) {
            Text(viewModel.activeTimerDurationText)
                .font(.system(size: isVeryCompact ? 44 : (isCompact ? 56 : 68), weight: .semibold, design: .rounded).monospacedDigit())
                .tracking(isVeryCompact ? 1.1 : (isCompact ? 1.8 : 2.4))
                .foregroundStyle(AppColors.primaryText)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.32), value: viewModel.activeTimerDurationText)

            Text(subheadlineText)
                .font(.system(size: isCompact ? 14 : 15, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .contentTransition(.interpolate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isCompact ? 16 : 24)
        .padding(.vertical, isCompact ? 16 : 22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppearancePreferences.isDarkMode ? AppColors.elevatedControlFill.opacity(1) : Color.white.opacity(0.84),
                            AppearancePreferences.isDarkMode ? Color(hex: "#14213A")!.opacity(0.96) : Color(hex: "#EEF4FF")!.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: "#A4C7FF")!.opacity(AppearancePreferences.isDarkMode ? 0.42 : 0.72),
                                Color(hex: "#C7B5FF")!.opacity(AppearancePreferences.isDarkMode ? 0.38 : 0.72)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
        }
        .shadow(color: AppColors.accentGlow.opacity(AppearancePreferences.isDarkMode ? 0.95 : 0.55), radius: 18, y: 10)
    }

    private func metricPill(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 11 : 12, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: isCompact ? 16 : 20, height: isCompact ? 16 : 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: isCompact ? 11 : 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(value)
                    .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, isCompact ? 12 : 14)
        .padding(.vertical, isCompact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.elevatedControlFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.elevatedControlBorder, lineWidth: 1)
        }
    }

    private var actionDock: some View {
        HStack(spacing: isCompact ? 10 : 12) {
            Button {
                if isActive {
                    viewModel.pauseTimer()
                } else {
                    viewModel.startTimer()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: primaryActionIcon)
                        .font(.system(size: isCompact ? 13 : 14, weight: .bold))
                    Text(primaryActionTitle)
                        .font(.system(size: isCompact ? 14 : 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: isCompact ? 42 : 46)
            }
            .buttonStyle(TimerPrimaryDockButtonStyle(isEnabled: viewModel.selectedProject != nil || isActive))
            .disabled((isActive == false && viewModel.selectedProject == nil))

            Button {
                if isActive {
                    viewModel.stopTimer()
                }
            } label: {
                Label("Завершить", systemImage: "stop.fill")
                    .font(.system(size: isCompact ? 13 : 14, weight: .semibold))
                    .frame(height: isCompact ? 42 : 46)
                    .frame(maxWidth: isCompact ? 124 : 148)
            }
            .buttonStyle(TimerSecondaryDockButtonStyle(kind: .stop))
            .disabled(isActive == false)

            Button {
                beginRateEditing()
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: isCompact ? 14 : 15, weight: .semibold))
                    .frame(width: isCompact ? 42 : 46, height: isCompact ? 42 : 46)
            }
            .buttonStyle(TimerIconDockButtonStyle())
        }
    }

    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            heroLabel("Проект")

            HStack(spacing: 12) {
                if let project = viewModel.selectedProject {
                    ProjectDot(colorHex: project.colorHex, size: 12)
                } else {
                    Circle()
                        .fill(AppColors.secondaryText.opacity(0.45))
                        .frame(width: 10, height: 10)
                }

                Text(viewModel.selectedProject?.name ?? "Выберите проект")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 10)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .rotationEffect(.degrees(isProjectListPresented ? 180 : 0))
            }
            .padding(.horizontal, isCompact ? 12 : 14)
            .frame(width: isVeryCompact ? nil : (isCompact ? 220 : 270), height: 42, alignment: .leading)
            .frame(maxWidth: isVeryCompact ? .infinity : nil)
            .background(controlBackground(isEmphasized: isProjectListPresented))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onTapGesture {
                guard isActive == false else { return }
                withAnimation(.snappy(duration: 0.26, extraBounce: 0.02)) {
                    isProjectListPresented.toggle()
                }
            }
            .overlay(alignment: .topLeading) {
                if isProjectListPresented {
                    projectDropdown
                        .offset(y: 52)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var projectDropdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.projects, id: \.id) { project in
                Button {
                    viewModel.selectedProjectID = project.id
                    withAnimation(.smooth(duration: 0.22)) {
                        isProjectListPresented = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        ProjectDot(colorHex: project.colorHex, size: 12)

                        Text(project.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.primaryText)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        if viewModel.selectedProjectID == project.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.selectedAccent)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(dropdownRowBackground(for: project))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHover { isHovering in
                    hoverProjectID = isHovering ? project.id : nil
                }
            }
        }
        .padding(8)
        .frame(width: isCompact ? 220 : 270)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.dropdownFill)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.solidControlBorder, lineWidth: 1)
        }
        .shadow(color: AppColors.strongShadow.opacity(0.92), radius: 18, y: 10)
    }

    private var rateControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            heroLabel("Ставка")

            Button {
                beginRateEditing()
            } label: {
                HStack(spacing: 8) {
                    if isEditingRate {
                        TextField("", text: Binding(
                            get: { rateDraft },
                            set: { rateDraft = sanitizeRateInput($0) }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .focused($isRateFieldFocused)
                        .onSubmit {
                            finishRateEditing()
                        }

                        Text("₽/ч")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                    } else {
                        Text(viewModel.rateFieldValueText + "/ч")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .padding(.horizontal, 14)
            }
            .buttonStyle(.plain)
            .background(controlBackground(isEmphasized: isEditingRate || isRateFieldFocused))
            .overlay(alignment: .trailing) {
                if viewModel.hasCustomRateOverride && isEditingRate == false {
                    Button {
                        clearRateOverride()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
            }
            .frame(width: isVeryCompact ? nil : (isCompact ? 132 : 170))
            .frame(maxWidth: isVeryCompact ? .infinity : nil)
        }
    }

    private func heroLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.secondaryText)
    }

    private func controlBackground(isEmphasized: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isEmphasized ? AppColors.solidControlFill : AppColors.elevatedControlFill)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isEmphasized ? AppColors.accentBorder : AppColors.solidControlBorder,
                        lineWidth: 1
                    )
            }
    }

    private func dropdownRowBackground(for project: Project) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(
                viewModel.selectedProjectID == project.id
                ? AppColors.selectedRowFill
                : (hoverProjectID == project.id ? AppColors.dropdownRowFill : Color.clear)
            )
    }

    private var statusTitle: String {
        if isPaused {
            return "На паузе"
        }

        if isActive {
            return "В работе"
        }

        return "Готов к запуску"
    }

    private var statusIcon: String {
        if isPaused {
            return "pause.fill"
        }

        if isActive {
            return "play.fill"
        }

        return "sparkles"
    }

    private var statusColor: Color {
        if isPaused {
            return Color(hex: "#E38B2C")!
        }

        if isActive {
            return Color(hex: "#2A8AA1")!
        }

        return Color(hex: "#6B58D6")!
    }

    private var subheadlineText: String {
        if isPaused {
            return "Сессия поставлена на паузу. Продолжите, когда будете готовы."
        }

        if isActive {
            return "Таймер уже идёт. Доход считается по ставке этой сессии."
        }

        return "Выберите проект, при необходимости скорректируйте ставку и запустите таймер."
    }

    private var primaryActionTitle: String {
        if isPaused {
            return "Продолжить"
        }

        if isActive {
            return "Пауза"
        }

        return "Запустить таймер"
    }

    private var primaryActionIcon: String {
        if isPaused {
            return "play.fill"
        }

        if isActive {
            return "pause.fill"
        }

        return "play.fill"
    }

    private func beginRateEditing() {
        guard isEditingRate == false else { return }
        rateDraft = sanitizeRateInput(viewModel.rateEditingText())
        isEditingRate = true
        isProjectListPresented = false
        Task { @MainActor in
            isRateFieldFocused = true
        }
    }

    private func finishRateEditing() {
        let sanitizedDraft = sanitizeRateInput(rateDraft)
        isEditingRate = false
        isRateFieldFocused = false
        viewModel.commitCustomRate(sanitizedDraft)
    }

    private func clearRateOverride() {
        rateDraft = ""
        isEditingRate = false
        isRateFieldFocused = false
        viewModel.commitCustomRate("")
    }

    private func sanitizeRateInput(_ value: String) -> String {
        var result = ""
        var hasSeparator = false

        for character in value {
            if character.isNumber {
                result.append(character)
            } else if character == "," || character == "." {
                guard hasSeparator == false else { continue }
                result.append(",")
                hasSeparator = true
            }
        }

        return result
    }
}

private struct TimerPrimaryDockButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppColors.inverseText)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.primaryActionFill.opacity(isEnabled ? (configuration.isPressed ? 0.84 : 1) : 0.42))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0.08), lineWidth: 1)
            }
            .shadow(color: AppColors.accentGlow.opacity(isEnabled ? 1 : 0), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TimerSecondaryDockButtonStyle: ButtonStyle {
    enum Kind {
        case stop
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(kind == .stop ? AppColors.errorText : AppColors.primaryText)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.elevatedControlFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        kind == .stop ? AppColors.errorText.opacity(0.24) : AppColors.solidControlBorder,
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct TimerIconDockButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AppColors.primaryText)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.elevatedControlFill)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColors.solidControlBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
