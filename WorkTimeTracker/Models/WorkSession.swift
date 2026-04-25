import Foundation
import SwiftData

@Model
final class WorkSession {
    var id: UUID
    var project: Project?
    var startTime: Date
    var endTime: Date?
    var durationSeconds: TimeInterval
    var note: String?
    private var tagsStorage: String
    var customHourlyRate: Decimal?
    var resolvedHourlyRateSnapshot: Decimal
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        project: Project? = nil,
        startTime: Date,
        endTime: Date? = nil,
        durationSeconds: TimeInterval = 0,
        note: String? = nil,
        tags: [String] = [],
        customHourlyRate: Decimal? = nil,
        resolvedHourlyRateSnapshot: Decimal = .zero,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.project = project
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.note = note
        self.tagsStorage = Self.serializeTags(tags)
        self.customHourlyRate = customHourlyRate
        self.resolvedHourlyRateSnapshot = resolvedHourlyRateSnapshot
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var tags: [String] {
        get {
            Self.deserializeTags(tagsStorage)
        }
        set {
            tagsStorage = Self.serializeTags(newValue)
        }
    }

    private static func serializeTags(_ tags: [String]) -> String {
        tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: "\n")
    }

    private static func deserializeTags(_ rawValue: String) -> [String] {
        rawValue
            .split(separator: "\n")
            .map { String($0) }
    }
}
