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
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()

                if let subtitle, subtitle.isEmpty == false {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
