import Foundation
import SwiftData

@MainActor
final class ProjectRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll(includeArchived: Bool = true) throws -> [Project] {
        let descriptor: FetchDescriptor<Project>

        if includeArchived {
            descriptor = FetchDescriptor<Project>(
                sortBy: [
                    SortDescriptor<Project>(\.updatedAt, order: .reverse)
                ]
            )
        } else {
            descriptor = FetchDescriptor<Project>(
                predicate: #Predicate<Project> { $0.isArchived == false },
                sortBy: [SortDescriptor<Project>(\.updatedAt, order: .reverse)]
            )
        }

        return try modelContext.fetch(descriptor)
    }

    func insert(_ project: Project) throws {
        modelContext.insert(project)
        try modelContext.save()
    }

    func fetchAllByID() throws -> [UUID: Project] {
        Dictionary(uniqueKeysWithValues: try fetchAll().map { ($0.id, $0) })
    }

    func save() throws {
        try modelContext.save()
    }

    func archive(_ project: Project) throws {
        project.isArchived = true
        project.updatedAt = .now
        try modelContext.save()
    }

    func unarchive(_ project: Project) throws {
        project.isArchived = false
        project.updatedAt = .now
        try modelContext.save()
    }

    func delete(_ project: Project) throws {
        modelContext.delete(project)
        try modelContext.save()
    }
}
