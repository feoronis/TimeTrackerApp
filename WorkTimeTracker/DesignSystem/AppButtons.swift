import SwiftUI

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.primaryActionFill.opacity(configuration.isPressed ? 0.82 : 1))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(AppearancePreferences.isDarkMode ? 0.14 : 0.55), lineWidth: 1)
            }
            .shadow(color: AppColors.accentGlow.opacity(AppearancePreferences.isDarkMode ? 1 : 0.9), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(AppearancePreferences.isLiquidGlassEnabled ? AppColors.tileFill : (AppearancePreferences.isDarkMode ? AppColors.tertiaryBackground.opacity(0.78) : AppColors.cardFill))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppColors.fieldBorder.opacity(AppearancePreferences.isDarkMode ? 1 : 0.95), lineWidth: 1)
            }
            .shadow(color: AppColors.glassShadow.opacity(AppearancePreferences.isDarkMode ? 0.75 : 0.25), radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GlassDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColors.destructive.opacity(configuration.isPressed ? 0.82 : (AppearancePreferences.isLiquidGlassEnabled ? 0.92 : 1)))
            )
            .overlay {
                if AppearancePreferences.isLiquidGlassEnabled {
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
            }
            .shadow(color: AppColors.destructive.opacity(AppearancePreferences.isDarkMode ? 0.3 : 0.14), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
