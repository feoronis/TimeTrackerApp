import SwiftUI

struct ProjectDot: View {
    let colorHex: String
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(Color(hex: colorHex) ?? AppColors.accent)
            .frame(width: size, height: size)
    }
}
