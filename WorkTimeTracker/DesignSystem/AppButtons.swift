import SwiftUI

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.glassHighlight.opacity(configuration.isPressed ? 0.16 : 0.28),
                                AppColors.accent.opacity(configuration.isPressed ? 0.22 : 0.34)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppColors.glassHighlight.opacity(0.55), lineWidth: 1)
            }
            .shadow(color: AppColors.glassShadow, radius: 10, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule(style: .continuous)
                    .fill(.thinMaterial)
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(AppColors.glassHighlight.opacity(0.35), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
