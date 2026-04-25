import Foundation
import SwiftData

@MainActor
final class SessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [WorkSession] {
        let descriptor = FetchDescriptor<WorkSession>(
            sortBy: [SortDescriptor<WorkSession>(\.startTime, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRecent(limit: Int) throws -> [WorkSession] {
        var descriptor = FetchDescriptor<WorkSession>(
            sortBy: [SortDescriptor<WorkSession>(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func fetchActiveSessions() throws -> [WorkSession] {
        var descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate<WorkSession> { $0.endTime == nil },
            sortBy: [SortDescriptor<WorkSession>(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 2

        return try modelContext.fetch(descriptor)
    }

    func fetchActiveSession() throws -> WorkSession? {
        try fetchActiveSessions().first
    }

    func insert(_ session: WorkSession) throws {
        modelContext.insert(session)
        try modelContext.save()
    }

    func fetchAllByID() throws -> [UUID: WorkSession] {
        Dictionary(uniqueKeysWithValues: try fetchAll().map { ($0.id, $0) })
    }

    func delete(_ session: WorkSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }
}
