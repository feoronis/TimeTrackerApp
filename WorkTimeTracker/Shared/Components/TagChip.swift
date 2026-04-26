import SwiftUI

struct TagChip: View {
    let title: String
    let color: Color
    var isSelected = false

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppearancePreferences.isDarkMode ? AppColors.inverseText : AppColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(isSelected ? (AppearancePreferences.isLiquidGlassEnabled ? 0.28 : 0.34) : (AppearancePreferences.isLiquidGlassEnabled ? 0.18 : 0.24)))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        color.opacity(isSelected ? 0.98 : (AppearancePreferences.isLiquidGlassEnabled ? 0.56 : 0.42)),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .overlay {
                if AppearancePreferences.isLiquidGlassEnabled {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppColors.cardInnerHighlight.opacity(AppearancePreferences.isDarkMode ? 0.8 : 0.4))
                }
            }
    }
}
