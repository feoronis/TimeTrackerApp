import SwiftUI

struct CalendarSidebarCard: View {
    @Bindable var viewModel: CalendarViewModel
    let availableWidth: CGFloat
    @Namespace private var selectedDayAnimation

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 7)
    private var isCompact: Bool { availableWidth < 760 }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: isCompact ? AppSpacing.lg : AppSpacing.xl) {
                HStack {
                    Text(viewModel.monthTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Spacer()

                    Button {
                        withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                            viewModel.showPreviousMonth()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(CalendarMonthButtonStyle())

                    Button {
                        withAnimation(.snappy(duration: 0.36, extraBounce: 0.02)) {
                            viewModel.showNextMonth()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(CalendarMonthButtonStyle())
                }

                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(AppFormatters.calendarWeekdaySymbols(), id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColors.secondaryText)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(viewModel.monthDays) { item in
                        Button {
                            withAnimation(.snappy(duration: 0.34, extraBounce: 0.03)) {
                                viewModel.selectDate(item.date)
                            }
                        } label: {
                            CalendarDayCell(
                                item: item,
                                currencyCode: viewModel.currencyCode,
                                selectionAnimation: selectedDayAnimation,
                                isCompact: isCompact
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .animation(.smooth(duration: 0.30), value: viewModel.displayedMonth)
        .animation(.snappy(duration: 0.30, extraBounce: 0.02), value: viewModel.selectedDate)
    }
}

private struct CalendarDayCell: View {
    let item: CalendarDayItem
    let currencyCode: String
    let selectionAnimation: Namespace.ID
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if item.isSelected {
                Text("\(item.dayNumber)")
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    .frame(width: isCompact ? 24 : 28, height: isCompact ? 24 : 28)
                    .foregroundStyle(AppColors.inverseText)
                    .background(
                        Circle()
                            .fill(AppColors.selectedAccent)
                            .matchedGeometryEffect(id: "selected-day-circle", in: selectionAnimation)
                    )
            } else {
                Text("\(item.dayNumber)")
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    .foregroundStyle(AppColors.primaryText)
            }

            Text(item.totalDurationSeconds > 0 ? AppFormatters.compactDurationText(from: item.totalDurationSeconds) : "—")
                .font(isCompact ? .caption2 : .caption)
                .foregroundStyle(item.isWithinDisplayedMonth ? AppColors.secondaryText : AppColors.secondaryText.opacity(0.45))

            Text(item.totalIncome > .zero ? AppFormatters.currencyText(item.totalIncome, currencyCode: currencyCode) : "—")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(item.isWithinDisplayedMonth ? AppColors.secondaryText : AppColors.secondaryText.opacity(0.45))
                .lineLimit(1)

            HStack(spacing: 5) {
                ForEach(Array(item.projectColorHexes.prefix(3).enumerated()), id: \.offset) { item in
                    ProjectDot(colorHex: item.element, size: isCompact ? 8 : 9)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: isCompact ? 76 : 90, alignment: .topLeading)
        .padding(isCompact ? AppSpacing.xs : AppSpacing.sm)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(borderColor, lineWidth: item.isSelected ? 1.2 : 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(item.isWithinDisplayedMonth ? 1 : 0.42)
        .scaleEffect(item.isSelected ? 1.02 : 1)
        .offset(y: item.isSelected ? -1 : 0)
        .animation(.snappy(duration: 0.28, extraBounce: 0.02), value: item.isSelected)
    }

    private var background: some ShapeStyle {
        if item.isSelected {
            return AnyShapeStyle(AppColors.accentSoftFill)
        }

        return AnyShapeStyle(AppColors.cardSecondaryFill)
    }

    private var borderColor: Color {
        item.isSelected ? AppColors.accentBorder : AppColors.tableBorder
    }
}

private struct CalendarMonthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 34, height: 34)
            .foregroundStyle(AppColors.secondaryText)
            .background(AppColors.solidControlFill, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(AppColors.solidControlBorder, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
