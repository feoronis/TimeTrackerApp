import AppKit
import SwiftUI

enum AppearancePreferences {
    static let themeModeKey = "appearance.theme_mode"
    static let liquidGlassEnabledKey = "appearance.liquid_glass_enabled"
    static let timeFormatKey = "settings.time_format"
    static let firstDayOfWeekKey = "settings.first_day_of_week"

    static func preferredColorScheme() -> ColorScheme? {
        switch UserDefaults.standard.string(forKey: themeModeKey) ?? "system" {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    @MainActor
    static var isDarkMode: Bool {
        switch UserDefaults.standard.string(forKey: themeModeKey) ?? "system" {
        case "dark":
            return true
        case "light":
            return false
        default:
            break
        }

        let appearance = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        return appearance == .darkAqua
    }

    static var isLiquidGlassEnabled: Bool {
        if UserDefaults.standard.object(forKey: liquidGlassEnabledKey) == nil {
            return true
        }

        return UserDefaults.standard.bool(forKey: liquidGlassEnabledKey)
    }

    static var preferredTimeFormat: String {
        UserDefaults.standard.string(forKey: timeFormatKey) ?? "24h"
    }

    static var preferredFirstDayOfWeek: Int {
        let value = UserDefaults.standard.integer(forKey: firstDayOfWeekKey)
        return value == 0 ? 2 : value
    }
}
