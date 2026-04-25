import Foundation
import Testing
@testable import WorkTimeTracker

struct SessionCalculatorTests {
    private let calculator = SessionCalculator()

    @Test
    func customRateHasHighestPriority() {
        let rate = calculator.resolvedRate(
            sessionCustomRate: Decimal(300),
            projectRate: Decimal(200),
            defaultRate: Decimal(100)
        )

        #expect(rate == Decimal(300))
    }

    @Test
    func projectRateOverridesDefaultRate() {
        let rate = calculator.resolvedRate(
            sessionCustomRate: nil,
            projectRate: Decimal(200),
            defaultRate: Decimal(100)
        )

        #expect(rate == Decimal(200))
    }

    @Test
    func sessionIncomeUsesResolvedSnapshot() {
        let session = WorkSession(
            startTime: Date(timeIntervalSince1970: 0),
            endTime: Date(timeIntervalSince1970: 3600),
            durationSeconds: 3600,
            resolvedHourlyRateSnapshot: Decimal(125)
        )

        #expect(calculator.sessionIncome(session) == Decimal(125))
    }

    @Test
    func completedSessionValuesPreserveHistoricalSnapshot() {
        let projectRateAtCreation = Decimal(150)
        let values = calculator.calculateCompletedSessionValues(
            start: Date(timeIntervalSince1970: 0),
            end: Date(timeIntervalSince1970: 7200),
            sessionCustomRate: nil,
            projectRate: projectRateAtCreation,
            defaultRate: Decimal(100)
        )

        let changedProjectRate = Decimal(250)

        #expect(values.resolvedHourlyRateSnapshot == Decimal(150))
        #expect(values.income == Decimal(300))
        #expect(changedProjectRate != values.resolvedHourlyRateSnapshot)
    }
}
