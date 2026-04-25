import Foundation

enum AppFormatters {
    private static let russianLocale = Locale(identifier: "ru_RU")
    private static let russianCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = russianLocale
        calendar.firstWeekday = 2
        return calendar
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter
    }()

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter
    }()

    private static let statusTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = russianLocale
        formatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = russianLocale
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func dateTimeText(_ date: Date) -> String {
        dateTimeFormatter.string(from: date)
    }

    static func timeText(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func dateText(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    static func shortDateText(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    static func monthYearText(_ date: Date) -> String {
        monthYearFormatter.string(from: date).capitalized(with: russianLocale)
    }

    static func dayMonthText(_ date: Date) -> String {
        dayMonthFormatter.string(from: date)
    }

    static func statusTimeText(_ date: Date) -> String {
        statusTimeFormatter.string(from: date)
    }

    static func durationText(from duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func compactDurationText(from duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded(.down))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        }

        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes)м"
        }

        return "\(seconds)с"
    }

    static func comparisonDurationText(_ delta: TimeInterval) -> String {
        let prefix = delta >= 0 ? "+" : "−"
        return prefix + compactDurationText(from: abs(delta))
    }

    static func decimalText(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    static func currencyText(_ value: Decimal, currencyCode: String) -> String {
        currencyFormatter.currencyCode = currencyCode
        return currencyFormatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
    }

    static func comparisonCurrencyText(_ value: Decimal, currencyCode: String) -> String {
        let prefix = value >= .zero ? "+" : "−"
        return prefix + currencyText(abs(value), currencyCode: currencyCode)
    }

    static func calendarWeekdaySymbols() -> [String] {
        let symbols = russianCalendar.shortStandaloneWeekdaySymbols
        guard symbols.count == 7 else {
            return ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
        }

        let reordered = Array(symbols[1...6]) + [symbols[0]]
        return reordered
            .map { $0.capitalized(with: russianLocale) }
    }

    static func relativeSessionStartText(_ date: Date, now: Date = .now, calendar: Calendar = russianCalendar) -> String {
        let timeText = statusTimeText(date)

        if calendar.isDate(date, inSameDayAs: now) {
            return timeText
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Вчера \(timeText)"
        }

        return "\(shortDateText(date)) \(timeText)"
    }
}
