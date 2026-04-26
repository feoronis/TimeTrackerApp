import Foundation

struct SessionCalculator {
    init() {}

    enum RoundingMode: String {
        case none
        case up
        case down
        case nearest
    }

    func resolvedRate(
        sessionCustomRate: Decimal?,
        projectRate: Decimal?,
        defaultRate: Decimal
    ) -> Decimal {
        if let sessionCustomRate {
            return sessionCustomRate
        }

        if let projectRate {
            return projectRate
        }

        return defaultRate
    }

    func durationSeconds(start: Date, end: Date) -> TimeInterval {
        max(0, end.timeIntervalSince(start))
    }

    func billableDurationSeconds(
        rawDurationSeconds: TimeInterval,
        roundingMode: RoundingMode,
        roundingMinutes: Int
    ) -> TimeInterval {
        guard roundingMode != .none, roundingMinutes > 0 else {
            return max(0, rawDurationSeconds)
        }

        let roundingUnit = TimeInterval(roundingMinutes * 60)
        let ratio = rawDurationSeconds / roundingUnit

        switch roundingMode {
        case .none:
            return max(0, rawDurationSeconds)
        case .up:
            return ceil(ratio) * roundingUnit
        case .down:
            return floor(ratio) * roundingUnit
        case .nearest:
            return ratio.rounded() * roundingUnit
        }
    }

    func income(
        durationSeconds: TimeInterval,
        hourlyRate: Decimal
    ) -> Decimal {
        guard durationSeconds > 0 else {
            return .zero
        }

        let hours = Decimal(durationSeconds) / Decimal(3600)
        return hours * hourlyRate
    }

    func sessionIncome(_ session: WorkSession) -> Decimal {
        if let fixedIncomeAmount = session.fixedIncomeAmount {
            return fixedIncomeAmount
        }

        return income(
            durationSeconds: session.durationSeconds,
            hourlyRate: session.resolvedHourlyRateSnapshot
        )
    }

    func calculateCompletedSessionValues(
        start: Date,
        end: Date,
        sessionCustomRate: Decimal?,
        projectRate: Decimal?,
        defaultRate: Decimal,
        roundingMode: RoundingMode = .none,
        roundingMinutes: Int = 0,
        fixedIncomeAmount: Decimal? = nil
    ) -> CompletedSessionValues {
        let rawDuration = durationSeconds(start: start, end: end)
        let duration = billableDurationSeconds(
            rawDurationSeconds: rawDuration,
            roundingMode: roundingMode,
            roundingMinutes: roundingMinutes
        )
        let resolvedRate = resolvedRate(
            sessionCustomRate: sessionCustomRate,
            projectRate: projectRate,
            defaultRate: defaultRate
        )

        return CompletedSessionValues(
            durationSeconds: duration,
            resolvedHourlyRateSnapshot: resolvedRate,
            income: fixedIncomeAmount ?? income(durationSeconds: duration, hourlyRate: resolvedRate)
        )
    }
}

struct CompletedSessionValues {
    let durationSeconds: TimeInterval
    let resolvedHourlyRateSnapshot: Decimal
    let income: Decimal
}
