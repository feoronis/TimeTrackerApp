import Foundation

@MainActor
final class CloudSyncStatusService {
    enum SyncStatus {
        case disabled
        case available
    }

    init() {}

    func status(isEnabled: Bool) -> SyncStatus {
        isEnabled ? .available : .disabled
    }
}
