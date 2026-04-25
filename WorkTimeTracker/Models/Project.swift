import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String?
    var hourlyRate: Decimal?
    var isArchived: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#4C8BF5",
        iconName: String? = nil,
        hourlyRate: Decimal? = nil,
        isArchived: Bool = false,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.hourlyRate = hourlyRate
        self.isArchived = isArchived
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
