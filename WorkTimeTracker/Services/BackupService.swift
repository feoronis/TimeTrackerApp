import Foundation

@MainActor
struct BackupService {
    private let exportService: ExportService

    init(exportService: ExportService) {
        self.exportService = exportService
    }

    func createBackup() throws -> URL {
        let snapshot = try exportService.buildSnapshot()
        let data = try JSONEncoder.snapshotEncoder.encode(snapshot)

        let backupDirectory = try ensureBackupDirectory()
        let backupURL = backupDirectory.appendingPathComponent(
            "backup-\(Date.fileTimestamp).json"
        )

        try data.write(to: backupURL, options: .atomic)
        return backupURL
    }

    private func ensureBackupDirectory() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = applicationSupport
            .appendingPathComponent("WorkTimeTracker", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }
}
