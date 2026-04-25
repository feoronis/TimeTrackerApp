import Foundation
import SwiftData

@Model
final class DayNote {
    var id: UUID
    var date: Date
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
