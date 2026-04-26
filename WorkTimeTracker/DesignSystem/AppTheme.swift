import SwiftUI

@MainActor
enum AppColors {
    private static var isDarkMode: Bool {
        AppearancePreferences.isDarkMode
    }

    static var accent: Color { blue }
    static var blue: Color { Color(hex: "#5B7CFA")! }
    static var purple: Color { Color(hex: "#8F5CF6")! }
    static var pink: Color { Color(hex: "#EF4444")! }
    static var orange: Color { Color(hex: "#F59E0B")! }
    static var green: Color { Color(hex: "#22C55E")! }
    static var yellow: Color { Color(hex: "#F4D65A")! }
    static var primaryText: Color { isDarkMode ? Color(hex: "#E2E8F0")! : Color(hex: "#1F2937")! }
    static var secondaryText: Color { isDarkMode ? Color(hex: "#94A3B8")! : Color(hex: "#6B7280")! }
    static var mutedText: Color { isDarkMode ? Color(hex: "#64748B")! : Color(hex: "#94A3B8")! }
    static var inverseText: Color { .white }
    static var windowBackground: Color { isDarkMode ? Color(hex: "#020617")! : Color(hex: "#F8FAFC")! }
    static var secondaryBackground: Color { isDarkMode ? Color(hex: "#0F172A")! : .white }
    static var tertiaryBackground: Color { isDarkMode ? Color(hex: "#1E293B")! : Color(hex: "#EEF2FF")! }
    static var controlBackground: Color { isDarkMode ? Color(hex: "#020617")!.opacity(0.64) : .white }
    static var focusedAccent: Color { blue }
    static var selectedAccent: Color { blue }
    static var primaryActionFill: Color { blue }
    static var accentSoftFill: Color { isDarkMode ? blue.opacity(0.18) : Color(hex: "#EEF2FF")! }
    static var accentSoftFillStrong: Color { isDarkMode ? blue.opacity(0.24) : Color(hex: "#E0E7FF")! }
    static var accentBorder: Color { isDarkMode ? blue.opacity(0.48) : blue.opacity(0.34) }
    static var accentGlow: Color { isDarkMode ? blue.opacity(0.28) : blue.opacity(0.14) }
    static var errorText: Color { pink }
    static var successText: Color { green }
    static var warningText: Color { orange }
    static var elevatedBackground: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? Color(hex: "#0F172A")!.opacity(0.78) : Color.white.opacity(0.76)
        }

        return isDarkMode ? Color(hex: "#0F172A")!.opacity(0.9) : Color.white.opacity(0.9)
    }
    static var separator: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? .white.opacity(0.10) : .white.opacity(0.72)
        }

        return isDarkMode ? .white.opacity(0.06) : .black.opacity(0.06)
    }
    static var strongSeparator: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? .white.opacity(0.14) : .white.opacity(0.84)
        }

        return isDarkMode ? .white.opacity(0.10) : .black.opacity(0.08)
    }
    static var sidebarBackground: Color { isDarkMode ? Color(hex: "#0B0F1F")!.opacity(0.94) : Color.white.opacity(0.72) }
    static var glassHighlight: Color { isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.70) }
    static var glassShadow: Color { isDarkMode ? Color.black.opacity(0.48) : Color.black.opacity(0.08) }
    static var glassTintTop: Color { isDarkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.55) }
    static var glassTintBottom: Color { isDarkMode ? Color.white.opacity(0.02) : Color.white.opacity(0.18) }
    static var sidebarSelectionTop: Color { blue }
    static var sidebarSelectionBottom: Color { purple }
    static var sidebarHover: Color { isDarkMode ? Color.white.opacity(0.05) : Color(hex: "#EEF2FF")! }
    static var statIconBackground: Color { isDarkMode ? blue.opacity(0.18) : Color(hex: "#EEF2FF")! }
    static var timerGradientStart: Color { isDarkMode ? Color(hex: "#1E293B")! : blue }
    static var timerGradientEnd: Color { isDarkMode ? Color(hex: "#312E81")! : purple }
    static var timerHeroGradientTop: Color { Color(hex: "#3DA8FF")! }
    static var timerHeroGradientMiddle: Color { Color(hex: "#5B7CFA")! }
    static var timerHeroGradientBottom: Color { Color(hex: "#8F5CF6")! }
    static var timerHeroBorder: Color { Color.white.opacity(isDarkMode ? 0.22 : 0.26) }
    static var timerHeroOverlay: Color { Color.white.opacity(isDarkMode ? 0.15 : 0.20) }
    static var timerHeroOverlayStrong: Color { Color.white.opacity(isDarkMode ? 0.22 : 0.28) }
    static var timerHeroGlow: Color { Color(hex: "#6F6CFF")!.opacity(isDarkMode ? 0.42 : 0.20) }
    static var timerHeroHighlight: Color { Color(hex: "#DDE8FF")! }
    static var timerStartTop: Color { Color(hex: "#49C2FF")! }
    static var timerStartBottom: Color { Color(hex: "#1D7BFF")! }
    static var timerPauseTop: Color { Color(hex: "#FFC760")! }
    static var timerPauseBottom: Color { Color(hex: "#FF8A3D")! }
    static var timerStopTop: Color { Color(hex: "#FF6B5F")! }
    static var timerStopBottom: Color { Color(hex: "#EF3737")! }
    static var success: Color { green }
    static var destructive: Color { pink }
    static var panelTopTint: Color { isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.78) }
    static var panelBottomTint: Color { isDarkMode ? Color(hex: "#0F172A")!.opacity(0.88) : Color.white.opacity(0.94) }
    static var cardFill: Color { isDarkMode ? Color(hex: "#0F172A")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.76 : 0.92) : Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.80 : 0.96) }
    static var cardSecondaryFill: Color { isDarkMode ? Color(hex: "#111C31")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.82 : 0.96) : Color.white.opacity(0.76) }
    static var rowFill: Color { isDarkMode ? Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.045 : 0.035) : Color.white.opacity(0.7) }
    static var rowHoverFill: Color { isDarkMode ? Color.white.opacity(0.075) : Color.black.opacity(0.035) }
    static var cardBorder: Color { AppearancePreferences.isLiquidGlassEnabled ? (isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.78)) : separator.opacity(isDarkMode ? 1 : 0.8) }
    static var cardInnerHighlight: Color { isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.6) }
    static var solidControlFill: Color { isDarkMode ? Color(hex: "#15233A")!.opacity(0.92) : Color.white.opacity(0.94) }
    static var solidControlBorder: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    static var elevatedControlFill: Color { isDarkMode ? Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.08 : 0.07) : Color.white.opacity(0.74) }
    static var elevatedControlBorder: Color { isDarkMode ? Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.14 : 0.09) : Color.white.opacity(0.72) }
    static var dropdownFill: Color { isDarkMode ? Color(hex: "#0F172A")!.opacity(0.98) : Color.white.opacity(0.94) }
    static var dropdownRowFill: Color { isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.84) }
    static var selectedRowFill: Color { isDarkMode ? Color(hex: "#1C2A4A")!.opacity(0.88) : Color(hex: "#EEF2FF")! }
    static var tooltipFill: Color { isDarkMode ? Color(hex: "#101827")!.opacity(0.96) : Color.white.opacity(0.98) }
    static var tooltipBorder: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    static var chartGrid: Color { isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    static var chartAxis: Color { isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.05) }
    static var subtleShadow: Color { isDarkMode ? Color.black.opacity(0.26) : Color.black.opacity(0.08) }
    static var strongShadow: Color { isDarkMode ? Color.black.opacity(0.52) : Color.black.opacity(0.12) }
    static var fieldFill: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.74)
        }

        return controlBackground
    }
    static var fieldBorder: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? Color.white.opacity(0.12) : Color.white.opacity(0.84)
        }

        return separator
    }
    static var tileFill: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.70)
        }

        return elevatedBackground
    }
    static var tileBorder: Color {
        if AppearancePreferences.isLiquidGlassEnabled {
            return isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.78)
        }

        return separator
    }
    static var tableFill: Color {
        isDarkMode ? Color(hex: "#0D172B")!.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.88 : 0.96) : Color.white.opacity(0.72)
    }
    static var tableBorder: Color {
        isDarkMode ? Color.white.opacity(AppearancePreferences.isLiquidGlassEnabled ? 0.08 : 0.06) : Color.black.opacity(0.05)
    }

    static var windowGradient: LinearGradient {
        if isDarkMode {
            return LinearGradient(
                colors: [
                    Color(hex: "#1A1F3A")!,
                    Color(hex: "#0B0F1F")!,
                    Color(hex: "#020617")!
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [Color(hex: "#FFFFFF")!, Color(hex: "#F8FAFC")!, Color(hex: "#EEF2FF")!],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var sidebarGradient: LinearGradient {
        if isDarkMode {
            return LinearGradient(
                colors: [Color(hex: "#0B0F1F")!, Color(hex: "#0F172A")!],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: [Color.white.opacity(0.84), Color(hex: "#F8FAFC")!.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
