import SwiftUI

struct CalendarSidebarCard: View {
    @Bindable var viewModel: CalendarViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 7)

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                HStack {
                    Text(viewModel.monthTitle)
                        .font(.title2.weight(.semibold))

                    Spacer()

                    Button {
                        viewModel.showPreviousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(CalendarMonthButtonStyle())

                    Button {
                        viewModel.showNextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(CalendarMonthButtonStyle())
                }

                LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                    ForEach(AppFormatters.calendarWeekdaySymbols(), id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(viewModel.monthDays) { item in
                        Button {
                            viewModel.selectDate(item.date)
                        } label: {
                            CalendarDayCell(item: item, currencyCode: viewModel.currencyCode)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    let item: CalendarDayItem
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if item.isSelected {
                Text("\(item.dayNumber)")
                    .font(.headline)
                    .frame(width: 28, height: 28)
                    .background(AppColors.sidebarSelectionTop, in: Circle())
            } else {
                Text("\(item.dayNumber)")
                    .font(.headline)
            }

            Text(item.totalDurationSeconds > 0 ? AppFormatters.compactDurationText(from: item.totalDurationSeconds) : "—")
                .font(.caption)
                .foregroundStyle(item.isWithinDisplayedMonth ? .secondary : .tertiary)

            Text(item.totalIncome > .zero ? AppFormatters.currencyText(item.totalIncome, currencyCode: currencyCode) : "—")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(item.isWithinDisplayedMonth ? .secondary : .tertiary)
                .lineLimit(1)

            HStack(spacing: 5) {
                ForEach(Array(item.projectColorHexes.prefix(3).enumerated()), id: \.offset) { item in
                    ProjectDot(colorHex: item.element, size: 7)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 90, alignment: .topLeading)
        .padding(AppSpacing.sm)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: item.isSelected ? 1.2 : 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(item.isWithinDisplayedMonth ? 1 : 0.42)
    }

    private var background: some ShapeStyle {
        if item.isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.sidebarSelectionTop, AppColors.sidebarSelectionBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color.white.opacity(0.04))
    }

    private var borderColor: Color {
        item.isSelected ? AppColors.glassHighlight.opacity(0.44) : AppColors.glassHighlight.opacity(0.15)
    }
}

private struct CalendarMonthButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 34, height: 34)
            .background(.thinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(AppColors.glassHighlight.opacity(0.24), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
