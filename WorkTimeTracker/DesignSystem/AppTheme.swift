import SwiftUI

enum AppColors {
    static let accent = Color.accentColor
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)
    static let sidebarBackground = Color(nsColor: .underPageBackgroundColor)
    static let glassHighlight = Color.white.opacity(0.32)
    static let glassShadow = Color.black.opacity(0.10)
    static let glassTintTop = Color.white.opacity(0.28)
    static let glassTintBottom = Color.blue.opacity(0.08)
    static let sidebarSelectionTop = Color(red: 0.23, green: 0.47, blue: 0.93).opacity(0.34)
    static let sidebarSelectionBottom = Color(red: 0.12, green: 0.72, blue: 0.79).opacity(0.22)
    static let sidebarHover = Color.white.opacity(0.10)
    static let statIconBackground = Color.white.opacity(0.14)
    static let tagBackground = Color.white.opacity(0.12)
    static let success = Color(nsColor: .systemGreen)
    static let destructive = Color(nsColor: .systemRed)
}
