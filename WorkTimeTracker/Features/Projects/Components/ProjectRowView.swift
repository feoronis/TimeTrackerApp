import SwiftUI

struct ProjectRowView: View {
    let row: ProjectListRow
    let currencyCode: String
    let isSelected: Bool
    let onSelect: () -> Void
    let onArchiveToggle: () -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                ProjectDot(colorHex: row.colorHex, size: 14)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(row.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: row.iconName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)

                        Text(row.isArchived ? "Архив" : "Активный")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(row.isArchived ? AppColors.secondaryText : AppColors.green)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.mutedText)
            }

            HStack(spacing: AppSpacing.md) {
                metricBlock(title: "Ставка", value: rateText)
                metricBlock(title: "Время", value: AppFormatters.compactDurationText(from: row.totalDurationSeconds))
                metricBlock(title: "Доход", value: AppFormatters.currencyText(row.totalIncome, currencyCode: currencyCode))
            }
        }
        .padding(16)
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button("Открыть", action: onSelect)
            Button(row.isArchived ? "Вернуть из архива" : "В архив", action: onArchiveToggle)
        }
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var rateText: String {
        guard let hourlyRate = row.hourlyRate else {
            return "—"
        }

        return AppFormatters.currencyText(hourlyRate, currencyCode: currencyCode) + "/ч"
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppColors.blue.opacity(AppearancePreferences.isDarkMode ? 0.28 : 0.18),
                        AppColors.purple.opacity(AppearancePreferences.isDarkMode ? 0.18 : 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(isHovered ? AppColors.rowHoverFill : AppColors.rowFill)
    }

    private var borderColor: Color {
        if isSelected {
            return AppColors.accentBorder
        }

        return AppColors.tileBorder
    }

    private func metricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.mutedText)

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
