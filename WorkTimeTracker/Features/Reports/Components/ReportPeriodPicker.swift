import SwiftUI

struct ReportPeriodPicker: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            HStack(spacing: 10) {
                ForEach(viewModel.periodButtons) { option in
                    Button(option.title) {
                        withAnimation(.snappy(duration: 0.34, extraBounce: 0.02)) {
                            viewModel.setPeriod(option.period)
                        }
                    }
                    .buttonStyle(ReportsFilterButtonStyle(isActive: viewModel.filter.period == option.period))
                }
            }

            Spacer()

            DateRangeField(
                startDate: $viewModel.filter.customStartDate,
                endDate: $viewModel.filter.customEndDate
            )
            .onChange(of: viewModel.filter.customStartDate, initial: false) {
                if viewModel.filter.period == .custom {
                    viewModel.applyFilters()
                }
            }
            .onChange(of: viewModel.filter.customEndDate, initial: false) {
                if viewModel.filter.period == .custom {
                    viewModel.applyFilters()
                }
            }
        }
    }
}

private struct ReportsFilterButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? AppColors.inverseText : AppColors.secondaryText)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(background(configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isActive ? Color.white.opacity(0.18) : AppColors.fieldBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }

    private func background(_ isPressed: Bool) -> some ShapeStyle {
        if isActive {
            return AnyShapeStyle(AppColors.primaryActionFill.opacity(isPressed ? 0.86 : 1))
        }

        return AnyShapeStyle(AppColors.fieldFill)
    }
}
