import Foundation
import SwiftData

@MainActor
final class SettingsRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchOrCreateSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()

        if let existingSettings = try modelContext.fetch(descriptor).first {
            return existingSettings
        }

        let settings = AppSettings()
        modelContext.insert(settings)
        try modelContext.save()
        return settings
    }

    func save() throws {
        try modelContext.save()
    }
}
