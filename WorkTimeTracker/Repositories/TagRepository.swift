import Foundation
import SwiftData

@MainActor
final class TagRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>()
        return try modelContext.fetch(descriptor).sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    func fetchAllByID() throws -> [UUID: Tag] {
        Dictionary(uniqueKeysWithValues: try fetchAll().map { ($0.id, $0) })
    }

    func fetchByNormalizedName(_ normalizedName: String) throws -> Tag? {
        try fetchAll().first { Self.normalizedName(for: $0.name) == normalizedName }
    }

    func insert(_ tag: Tag) throws {
        modelContext.insert(tag)
        try modelContext.save()
    }

    func upsertMissingTags(named names: [String]) throws {
        let existingNormalizedNames = Set(try fetchAll().map { Self.normalizedName(for: $0.name) })
        var knownNames = existingNormalizedNames
        var hasChanges = false

        for name in names.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }).filter({ $0.isEmpty == false }) {
            let normalizedName = Self.normalizedName(for: name)
            guard knownNames.contains(normalizedName) == false else {
                continue
            }

            modelContext.insert(Tag(name: name))
            knownNames.insert(normalizedName)
            hasChanges = true
        }

        if hasChanges {
            try modelContext.save()
        }
    }

    func delete(_ tag: Tag) throws {
        modelContext.delete(tag)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }

    static func normalizedName(for value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
