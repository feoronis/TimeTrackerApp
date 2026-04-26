import Foundation

enum TimeFormatOption: String, CaseIterable, Identifiable {
    case hours24 = "24h"
    case hours12 = "12h"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hours24:
            return "24 часа"
        case .hours12:
            return "12 часов"
        }
    }
}

enum FirstDayOfWeekOption: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .sunday:
            return "Воскресенье"
        case .monday:
            return "Понедельник"
        }
    }
}

enum ThemeModeOption: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "Как в системе"
        case .light:
            return "Светлая"
        case .dark:
            return "Темная"
        }
    }
}

enum RoundingModeOption: String, CaseIterable, Identifiable {
    case none
    case up
    case down
    case nearest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "Без округления"
        case .up:
            return "Вверх"
        case .down:
            return "Вниз"
        case .nearest:
            return "До ближайшего"
        }
    }
}
