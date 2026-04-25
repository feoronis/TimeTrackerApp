import SwiftUI

struct TimerControlCard: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Активный проект")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Picker("", selection: $viewModel.selectedProjectID) {
                            Text("Выберите проект").tag(Optional<UUID>.none)

                            ForEach(viewModel.projects, id: \.id) { project in
                                Text(project.name).tag(Optional(project.id))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 320, alignment: .leading)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Spacer(minLength: AppSpacing.lg)

                    VStack(alignment: .trailing, spacing: AppSpacing.sm) {
                        Text("Ставка")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(viewModel.effectiveRateText)
                            .font(.headline.monospacedDigit())
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                VStack(spacing: AppSpacing.sm) {
                    Text(viewModel.activeTimerDurationText)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)

                    Text("Текущий доход")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.activeTimerIncomeText)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)

                TextField("Своя ставка, если нужна", text: $viewModel.customRateText)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: AppSpacing.md) {
                    Button("Start") {
                        viewModel.startTimer()
                    }
                    .buttonStyle(TimerActionButtonStyle(role: .primary))
                    .disabled(viewModel.timerService.activeSession != nil || viewModel.selectedProject == nil)

                    Button("Pause") {
                        viewModel.pauseTimer()
                    }
                    .buttonStyle(TimerActionButtonStyle(role: .secondary))
                    .disabled(viewModel.timerService.activeSession == nil)

                    Button("Stop") {
                        viewModel.stopTimer()
                    }
                    .buttonStyle(TimerActionButtonStyle(role: .destructive))
                    .disabled(viewModel.timerService.activeSession == nil)
                }
            }
        }
    }
}

private struct TimerActionButtonStyle: ButtonStyle {
    enum Role {
        case primary
        case secondary
        case destructive
    }

    let role: Role

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(backgroundColor(configuration.isPressed))
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppColors.glassHighlight.opacity(0.28), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch role {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return .white
        }
    }

    private func backgroundColor(_ isPressed: Bool) -> some ShapeStyle {
        switch role {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.63, blue: 0.47).opacity(isPressed ? 0.86 : 1),
                        Color(red: 0.10, green: 0.46, blue: 0.35).opacity(isPressed ? 0.86 : 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .secondary:
            return AnyShapeStyle(.thinMaterial)
        case .destructive:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppColors.destructive.opacity(isPressed ? 0.82 : 0.95),
                        Color(red: 0.63, green: 0.18, blue: 0.18).opacity(isPressed ? 0.82 : 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}
