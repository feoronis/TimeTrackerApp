import AppKit
import Foundation

enum BackupServiceError: LocalizedError, Equatable {
    case cancelled

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Выбор папки для резервных копий отменён."
        }
    }
}

struct BackupDirectorySelection {
    let path: String
    let bookmarkData: Data
}

@MainActor
struct BackupService {
    private let exportService: ExportService
    private let settingsRepository: SettingsRepository
    private let fileManager: FileManager
    private let applicationSupportDirectoryProvider: @Sendable () throws -> URL
    private let maxBackupFiles = 20

    init(
        exportService: ExportService,
        settingsRepository: SettingsRepository,
        fileManager: FileManager = .default,
        applicationSupportDirectoryProvider: @escaping @Sendable () throws -> URL = {
            try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
    ) {
        self.exportService = exportService
        self.settingsRepository = settingsRepository
        self.fileManager = fileManager
        self.applicationSupportDirectoryProvider = applicationSupportDirectoryProvider
    }

    func createBackup() throws -> URL {
        let settings = try settingsRepository.fetchOrCreateSettings()
        return try writeBackup(using: settings, prefix: "backup-manual")
    }

    func createAutomaticBackupIfEnabled() throws -> URL? {
        let settings = try settingsRepository.fetchOrCreateSettings()

        guard settings.autoBackupEnabled else {
            return nil
        }

        return try writeBackup(using: settings, prefix: "backup-auto")
    }

    func chooseBackupDirectory() throws -> BackupDirectorySelection {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Выбрать"
        panel.message = "Выберите папку для автоматических резервных копий."

        guard panel.runModal() == .OK, let url = panel.url else {
            throw BackupServiceError.cancelled
        }

        let bookmarkData = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        return BackupDirectorySelection(
            path: url.path,
            bookmarkData: bookmarkData
        )
    }

    func defaultBackupDirectoryPath() -> String {
        (try? defaultBackupDirectory().path) ?? "\(NSHomeDirectory())/Library/Application Support/WorkTimeTracker/Backups"
    }

    func resolvedBackupDirectoryPath(for settings: AppSettings?) -> String {
        settings?.autoBackupDirectoryPath?.nilIfEmpty ?? defaultBackupDirectoryPath()
    }

    private func writeBackup(using settings: AppSettings, prefix: String) throws -> URL {
        let snapshot = try exportService.buildSnapshot()
        let data = try JSONEncoder.snapshotEncoder.encode(snapshot)
        let directory = try resolvedBackupDirectory(for: settings)

        return try withSecurityScopedAccess(to: directory) { directory in
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )

            let backupURL = directory.appendingPathComponent(
                "\(prefix)-\(Date.fileTimestamp)-\(UUID().uuidString.prefix(8)).json"
            )

            try data.write(to: backupURL, options: .atomic)
            try pruneOldBackups(in: directory)
            return backupURL
        }
    }

    private func resolvedBackupDirectory(for settings: AppSettings) throws -> URL {
        if let customDirectory = try resolveCustomDirectory(for: settings) {
            do {
                try withSecurityScopedAccess(to: customDirectory) { directory in
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                return customDirectory
            } catch {
                return try defaultBackupDirectory()
            }
        }

        return try defaultBackupDirectory()
    }

    private func resolveCustomDirectory(for settings: AppSettings) throws -> URL? {
        if let bookmarkData = settings.autoBackupDirectoryBookmark {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale == false || settings.autoBackupDirectoryPath == nil {
                return url
            }
        }

        guard let customPath = settings.autoBackupDirectoryPath?.nilIfEmpty else {
            return nil
        }

        return URL(fileURLWithPath: customPath, isDirectory: true)
    }

    private func defaultBackupDirectory() throws -> URL {
        let applicationSupport = try applicationSupportDirectoryProvider()
        return applicationSupport
            .appendingPathComponent("WorkTimeTracker", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
    }

    private func pruneOldBackups(in directory: URL) throws {
        let backupURLs = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        )
        .filter { url in
            url.pathExtension == "json" && url.lastPathComponent.hasPrefix("backup-")
        }
        .sorted { lhs, rhs in
            resourceDate(for: lhs) < resourceDate(for: rhs)
        }

        guard backupURLs.count > maxBackupFiles else {
            return
        }

        for url in backupURLs.prefix(backupURLs.count - maxBackupFiles) {
            try fileManager.removeItem(at: url)
        }
    }

    private func resourceDate(for url: URL) -> Date {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        return values?.contentModificationDate ?? values?.creationDate ?? .distantPast
    }

    private func withSecurityScopedAccess<T>(to directory: URL, _ operation: (URL) throws -> T) throws -> T {
        let accessed = directory.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                directory.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(directory)
    }
}
