import Foundation
import SwiftData

@MainActor
final class DayNoteRepository {
    private let modelContext: ModelContext
    private let calendar: Calendar

    init(
        modelContext: ModelContext,
        calendar: Calendar = .current
    ) {
        self.modelContext = modelContext
        self.calendar = calendar
    }

    func fetch(for date: Date) throws -> DayNote? {
        let normalizedDate = calendar.startOfDay(for: date)
        let descriptor = FetchDescriptor<DayNote>(
            predicate: #Predicate<DayNote> { $0.date == normalizedDate }
        )

        return try modelContext.fetch(descriptor).first
    }

    func save(note: String, for date: Date) throws {
        let normalizedDate = calendar.startOfDay(for: date)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingNote = try fetch(for: normalizedDate) {
            existingNote.note = trimmedNote
            existingNote.updatedAt = .now

            if trimmedNote.isEmpty {
                modelContext.delete(existingNote)
            }
        } else if trimmedNote.isEmpty == false {
            let dayNote = DayNote(date: normalizedDate, note: trimmedNote)
            modelContext.insert(dayNote)
        }

        try modelContext.save()
    }

    func fetchAll() throws -> [DayNote] {
        let descriptor = FetchDescriptor<DayNote>(
            sortBy: [SortDescriptor<DayNote>(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllByID() throws -> [UUID: DayNote] {
        Dictionary(uniqueKeysWithValues: try fetchAll().map { ($0.id, $0) })
    }

    func insert(_ dayNote: DayNote) throws {
        modelContext.insert(dayNote)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }
}
