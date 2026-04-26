import SwiftUI

struct SummaryMetricCard: View {
    let title: String
    let value: String
    let subtitle: String?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)

                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(AppColors.primaryText)

                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
