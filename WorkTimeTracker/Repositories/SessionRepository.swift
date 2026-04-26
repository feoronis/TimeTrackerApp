import Foundation
import SwiftData

@MainActor
final class SessionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [WorkSession] {
        let descriptor = FetchDescriptor<WorkSession>()
        return sortBySessionEndTime(try modelContext.fetch(descriptor))
    }

    func fetchRecent(limit: Int) throws -> [WorkSession] {
        Array(try fetchAll().prefix(limit))
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

    func fetchSessions(projectID: UUID) throws -> [WorkSession] {
        let descriptor = FetchDescriptor<WorkSession>(
            predicate: #Predicate<WorkSession> { session in
                session.project?.id == projectID
            }
        )

        return try modelContext.fetch(descriptor)
    }

    func delete(_ session: WorkSession) throws {
        modelContext.delete(session)
        try modelContext.save()
    }

    func delete(_ sessions: [WorkSession]) throws {
        for session in sessions {
            modelContext.delete(session)
        }

        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }

    private func sortBySessionEndTime(_ sessions: [WorkSession]) -> [WorkSession] {
        sessions.sorted { lhs, rhs in
            let lhsDate = lhs.endTime ?? lhs.startTime
            let rhsDate = rhs.endTime ?? rhs.startTime

            if lhsDate == rhsDate {
                return lhs.startTime > rhs.startTime
            }

            return lhsDate > rhsDate
        }
    }
}
