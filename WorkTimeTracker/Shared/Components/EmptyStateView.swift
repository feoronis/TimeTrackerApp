import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xxl)
    }
}
