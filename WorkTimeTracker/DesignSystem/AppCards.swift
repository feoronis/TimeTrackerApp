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
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppMaterials.elevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.glassTintTop,
                                        AppColors.glassTintBottom
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(AppColors.glassHighlight.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: AppColors.glassShadow, radius: 18, y: 12)
    }
}
