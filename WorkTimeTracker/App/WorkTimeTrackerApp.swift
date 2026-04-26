import AppKit
import SwiftData
import SwiftUI

@main
struct WorkTimeTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppearancePreferences.themeModeKey) private var themeMode = "system"
    @AppStorage(AppearancePreferences.liquidGlassEnabledKey) private var liquidGlassEnabled = true
    private let sharedModelContainer: ModelContainer
    private let cloudSyncStartupState: CloudSyncStartupState
    @State private var appEnvironment: AppEnvironment

    init() {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self,
            Tag.self
        ])

        let cloudKitRequested = CloudSyncPreferences.isEnabled
        let preferredCloudDatabase: ModelConfiguration.CloudKitDatabase = cloudKitRequested ? .automatic : .none
        let preferredConfiguration = ModelConfiguration(
            "WorkTimeTracker",
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: preferredCloudDatabase
        )

        do {
            let bootstrap = try Self.makeModelContainer(
                schema: schema,
                preferredConfiguration: preferredConfiguration,
                cloudKitRequested: cloudKitRequested
            )
            sharedModelContainer = bootstrap.container
            cloudSyncStartupState = bootstrap.cloudSyncStartupState
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        _appEnvironment = State(
            initialValue: AppEnvironment(
                modelContainer: sharedModelContainer,
                cloudSyncStartupState: cloudSyncStartupState
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppRouterView()
                .environment(appEnvironment)
                .background(WindowActivationView())
                .id(appearanceIdentity)
                .tint(AppColors.blue)
                .preferredColorScheme(preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1440, height: 900)

        MenuBarExtra("TimeTrack", systemImage: appEnvironment.timerService.activeSession == nil ? "timer" : "timer.circle.fill") {
            MenuBarTimerView()
                .environment(appEnvironment)
        }
    }

    private static func makeModelContainer(
        schema: Schema,
        preferredConfiguration: ModelConfiguration,
        cloudKitRequested: Bool
    ) throws -> (container: ModelContainer, cloudSyncStartupState: CloudSyncStartupState) {
        do {
            return (
                try ModelContainer(for: schema, configurations: [preferredConfiguration]),
                CloudSyncStartupState(
                    mode: cloudKitRequested ? .cloudKitEnabled : .localOnly
                )
            )
        } catch {
            if cloudKitRequested {
                let fallbackConfiguration = ModelConfiguration(
                    "WorkTimeTracker",
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .none
                )

                return (
                    try ModelContainer(for: schema, configurations: [fallbackConfiguration]),
                    CloudSyncStartupState(mode: .fellBackToLocal(error.localizedDescription))
                )
            }

            try PersistentStoreRecovery.archiveDefaultStore(named: "WorkTimeTracker")
            return (
                try ModelContainer(for: schema, configurations: [preferredConfiguration]),
                CloudSyncStartupState(mode: .localOnly)
            )
        }
    }
}

private extension WorkTimeTrackerApp {
    var appearanceIdentity: String {
        "\(themeMode)-\(liquidGlassEnabled)"
    }

    var preferredColorScheme: ColorScheme? {
        switch themeMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct WindowActivationView: NSViewRepresentable {
    final class Coordinator {
        var didConfigureWindow = false
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            configureWindowIfNeeded(for: view, coordinator: context.coordinator)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindowIfNeeded(for: nsView, coordinator: context.coordinator)
        }
    }

    private func configureWindowIfNeeded(for view: NSView, coordinator: Coordinator) {
        guard coordinator.didConfigureWindow == false else { return }
        guard let window = view.window else {
            DispatchQueue.main.async {
                configureWindowIfNeeded(for: view, coordinator: coordinator)
            }
            return
        }

        coordinator.didConfigureWindow = true
        window.minSize = NSSize(width: 1280, height: 820)

        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
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
