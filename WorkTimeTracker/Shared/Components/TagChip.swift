import SwiftUI

struct TagChip: View {
    let title: String
    let color: Color
    var isSelected = false

    var body: some View {
        Text(title)
            .font(.callout.weight(.medium))
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(isSelected ? 0.24 : 0.12))
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(color.opacity(isSelected ? 0.34 : 0.18), lineWidth: 1)
            }
    }
}

