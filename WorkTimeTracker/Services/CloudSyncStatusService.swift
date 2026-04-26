import CloudKit
import Foundation
import Security

enum CloudSyncPreferences {
    static let isEnabledKey = "settings.icloud_sync_enabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: isEnabledKey)
    }

    static func setEnabled(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: isEnabledKey)
    }
}

struct CloudSyncStartupState: Sendable {
    enum Mode: Sendable {
        case localOnly
        case cloudKitEnabled
        case fellBackToLocal(String)
    }

    let mode: Mode
}

struct CloudSyncStatusService: Sendable {
    enum SyncStatus: Equatable {
        case disabled
        case restartRequiredToEnable
        case restartRequiredToDisable
        case active
        case unavailableNoAccount
        case unavailableRestricted
        case unavailableTemporarily
        case unavailableConfiguration(String)
    }

    private let startupState: CloudSyncStartupState
    private let hasCloudKitEntitlement: @Sendable () -> Bool
    private let accountStatusProvider: @Sendable () async throws -> CKAccountStatus

    init(
        startupState: CloudSyncStartupState,
        hasCloudKitEntitlement: @escaping @Sendable () -> Bool = CloudKitEnvironment.hasRequiredEntitlement,
        accountStatusProvider: @escaping @Sendable () async throws -> CKAccountStatus = {
            try await CKContainer.default().accountStatus()
        }
    ) {
        self.startupState = startupState
        self.hasCloudKitEntitlement = hasCloudKitEntitlement
        self.accountStatusProvider = accountStatusProvider
    }

    func status(isEnabled: Bool) async -> SyncStatus {
        guard isEnabled else {
            if case .cloudKitEnabled = startupState.mode {
                return .restartRequiredToDisable
            }

            return .disabled
        }

        switch startupState.mode {
        case .localOnly:
            return .restartRequiredToEnable
        case .fellBackToLocal(let errorDescription):
            return .unavailableConfiguration(errorDescription)
        case .cloudKitEnabled:
            guard hasCloudKitEntitlement() else {
                return .unavailableConfiguration("Для этой сборки не настроены iCloud entitlement.")
            }

            do {
                switch try await accountStatusProvider() {
                case .available:
                    return .active
                case .noAccount:
                    return .unavailableNoAccount
                case .restricted:
                    return .unavailableRestricted
                case .couldNotDetermine, .temporarilyUnavailable:
                    return .unavailableTemporarily
                @unknown default:
                    return .unavailableTemporarily
                }
            } catch {
                return .unavailableConfiguration(error.localizedDescription)
            }
        }
    }
}

private enum CloudKitEnvironment {
    static func hasRequiredEntitlement() -> Bool {
        guard let task = SecTaskCreateFromSelf(nil) else {
            return false
        }

        let entitlementKeys = [
            "com.apple.developer.icloud-services",
            "com.apple.developer.icloud-container-identifiers",
            "com.apple.developer.ubiquity-container-identifiers"
        ]

        for key in entitlementKeys {
            guard let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil) else {
                continue
            }

            if let items = value as? [String], items.isEmpty == false {
                return true
            }

            if let isEnabled = value as? Bool, isEnabled {
                return true
            }
        }

        return false
    }
}
