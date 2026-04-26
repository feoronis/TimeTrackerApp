import Foundation
import Testing
@testable import WorkTimeTracker

struct CloudSyncStatusServiceTests {
    @Test
    func reportsDisabledWhenPreferenceIsOffAndCloudKitWasNotRequested() async {
        let service = CloudSyncStatusService(
            startupState: CloudSyncStartupState(mode: .localOnly)
        )

        let status = await service.status(isEnabled: false)

        #expect(status == .disabled)
    }

    @Test
    func reportsRestartRequiredToEnableWhenPreferenceIsOnButAppStartedLocally() async {
        let service = CloudSyncStatusService(
            startupState: CloudSyncStartupState(mode: .localOnly)
        )

        let status = await service.status(isEnabled: true)

        #expect(status == .restartRequiredToEnable)
    }

    @Test
    func reportsFallbackFailureWhenCloudKitBootstrappingFailed() async {
        let service = CloudSyncStatusService(
            startupState: CloudSyncStartupState(mode: .fellBackToLocal("Missing entitlement"))
        )

        let status = await service.status(isEnabled: true)

        #expect(status == .unavailableConfiguration("Missing entitlement"))
    }

    @Test
    func reportsConfigurationIssueWithoutCloudKitEntitlement() async {
        let service = CloudSyncStatusService(
            startupState: CloudSyncStartupState(mode: .cloudKitEnabled),
            hasCloudKitEntitlement: { false },
            accountStatusProvider: { .available }
        )

        let status = await service.status(isEnabled: true)

        #expect(status == .unavailableConfiguration("Для этой сборки не настроены iCloud entitlement."))
    }

    @Test
    func reportsTemporaryUnavailableWhenAccountStatusThrows() async {
        struct StubError: LocalizedError {
            var errorDescription: String? { "network issue" }
        }

        let service = CloudSyncStatusService(
            startupState: CloudSyncStartupState(mode: .cloudKitEnabled),
            hasCloudKitEntitlement: { true },
            accountStatusProvider: { throw StubError() }
        )

        let status = await service.status(isEnabled: true)

        #expect(status == .unavailableConfiguration("network issue"))
    }
}
