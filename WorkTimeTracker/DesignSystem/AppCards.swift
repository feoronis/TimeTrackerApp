import SwiftUI

struct GlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardFill)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: AppearancePreferences.isLiquidGlassEnabled ? 1.1 : 1)
            }
            .shadow(color: shadowColor, radius: AppearancePreferences.isLiquidGlassEnabled ? 24 : 14, y: AppearancePreferences.isLiquidGlassEnabled ? 12 : 8)
            .overlay {
                if AppearancePreferences.isDarkMode && AppearancePreferences.isLiquidGlassEnabled {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppColors.cardInnerHighlight, lineWidth: 0.8)
                        .blur(radius: 0.8)
                }
            }
    }

    private var cardFill: some ShapeStyle {
        if AppearancePreferences.isDarkMode {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        AppColors.panelTopTint,
                        AppColors.panelBottomTint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        if AppearancePreferences.isLiquidGlassEnabled {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.78),
                        Color(hex: "#F8FAFC")!.opacity(0.68)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(AppColors.secondaryBackground.opacity(0.96))
    }

    private var borderColor: Color {
        AppColors.cardBorder
    }

    private var shadowColor: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return AppearancePreferences.isDarkMode
                ? AppColors.glassShadow.opacity(0.95)
                : AppColors.subtleShadow
        }

        return AppColors.glassShadow.opacity(AppearancePreferences.isDarkMode ? 0.7 : 0.32)
    }
}
