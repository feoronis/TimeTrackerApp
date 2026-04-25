import SwiftData
import SwiftUI

@main
struct WorkTimeTrackerApp: App {
    private let sharedModelContainer: ModelContainer
    @State private var appEnvironment: AppEnvironment

    init() {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self
        ])

        let configuration = ModelConfiguration(
            "WorkTimeTracker",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            sharedModelContainer = try Self.makeModelContainer(
                schema: schema,
                configuration: configuration
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        _appEnvironment = State(
            initialValue: AppEnvironment(modelContainer: sharedModelContainer)
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .environment(appEnvironment)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1280, height: 820)
    }

    private static func makeModelContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) throws -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            try PersistentStoreRecovery.archiveDefaultStore(named: "WorkTimeTracker")
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }
}

private enum PersistentStoreRecovery {
    static func archiveDefaultStore(named storeName: String) throws {
        let fileManager = FileManager.default
        let applicationSupportDirectory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let storeURL = applicationSupportDirectory.appending(path: "\(storeName).store")
        let shmURL = applicationSupportDirectory.appending(path: "\(storeName).store-shm")
        let walURL = applicationSupportDirectory.appending(path: "\(storeName).store-wal")

        guard fileManager.fileExists(atPath: storeURL.path)
            || fileManager.fileExists(atPath: shmURL.path)
            || fileManager.fileExists(atPath: walURL.path) else {
            return
        }

        let backupDirectory = applicationSupportDirectory
            .appending(path: "RecoveredStores", directoryHint: .isDirectory)
            .appending(path: timestamp(), directoryHint: .isDirectory)

        try fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        try moveIfPresent(storeURL, toDirectory: backupDirectory)
        try moveIfPresent(shmURL, toDirectory: backupDirectory)
        try moveIfPresent(walURL, toDirectory: backupDirectory)
    }

    private static func moveIfPresent(_ fileURL: URL, toDirectory directoryURL: URL) throws {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.moveItem(at: fileURL, to: directoryURL.appending(path: fileURL.lastPathComponent))
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")
    }
}
