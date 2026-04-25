import Foundation

extension JSONEncoder {
    static var snapshotEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(snapshotDateString(from: date))
        }
        return encoder
    }
}

extension JSONDecoder {
    static var snapshotDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = snapshotDate(from: value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Некорректная дата в snapshot."
                )
            }
            return date
        }
        return decoder
    }
}

extension Date {
    static var fileTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter.string(from: .now)
    }
}

func snapshotDateString(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

func snapshotDate(from value: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value)
}
