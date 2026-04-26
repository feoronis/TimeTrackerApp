import SwiftUI

struct ProjectRowView: View {
    let row: ProjectListRow
    let currencyCode: String
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ProjectDot(colorHex: row.colorHex, size: 16)
                Text(row.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: row.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 70)

            Text(rateText)
                .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 120, alignment: .trailing)

            Text(AppFormatters.compactDurationText(from: row.totalDurationSeconds))
                .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 100, alignment: .trailing)

            Text(AppFormatters.currencyText(row.totalIncome, currencyCode: currencyCode))
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 120, alignment: .trailing)

            Text(row.isArchived ? "Архив" : "Активный")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(row.isArchived ? AppColors.secondaryText : AppColors.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((row.isArchived ? Color.gray.opacity(0.14) : AppColors.green.opacity(0.14)), in: Capsule())
                .frame(width: 110)

            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: 28)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Редактировать", action: onEdit)
            Button(row.isArchived ? "Вернуть из архива" : "В архив", action: onArchiveToggle)
        }
        .onTapGesture(perform: onEdit)
    }

    private var rateText: String {
        guard let hourlyRate = row.hourlyRate else {
            return "—"
        }

        return AppFormatters.currencyText(hourlyRate, currencyCode: currencyCode) + "/ч"
    }
}
