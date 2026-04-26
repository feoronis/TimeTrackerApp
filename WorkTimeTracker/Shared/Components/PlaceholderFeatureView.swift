import SwiftUI

struct PlaceholderFeatureView: View {
    let title: String
    let description: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                GlassCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Экран подготовлен")
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)

                        Text(description)
                            .font(.body)
                            .foregroundStyle(AppColors.secondaryText)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.windowBackground)
    }
}
