import Foundation
import Observation

enum TimerServiceError: LocalizedError {
    case activeTimerAlreadyExists
    case multipleActiveTimersDetected
    case noActiveTimer
    case timerAlreadyPaused
    case timerIsNotPaused

    var errorDescription: String? {
        switch self {
        case .activeTimerAlreadyExists:
            return "Одновременно может работать только один таймер."
        case .multipleActiveTimersDetected:
            return "Обнаружено несколько активных таймеров. Сначала разберите сохраненные сессии."
        case .noActiveTimer:
            return "Нет активного таймера для остановки."
        case .timerAlreadyPaused:
            return "Таймер уже на паузе."
        case .timerIsNotPaused:
            return "Таймер сейчас не на паузе."
        }
    }
}

@Observable
@MainActor
final class TimerService {
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let sessionCalculator: SessionCalculator
    private var tickerTask: Task<Void, Never>?

    private(set) var activeSession: WorkSession?
    private(set) var currentDate = Date.now

    init(
        sessionRepository: SessionRepository,
        settingsRepository: SettingsRepository,
        sessionCalculator: SessionCalculator
    ) {
        self.sessionRepository = sessionRepository
        self.settingsRepository = settingsRepository
        self.sessionCalculator = sessionCalculator
    }

    func restoreActiveSessionIfNeeded() throws {
        let activeSessions = try sessionRepository.fetchActiveSessions()

        guard activeSessions.count <= 1 else {
            throw TimerServiceError.multipleActiveTimersDetected
        }

        activeSession = activeSessions.first
        currentDate = activeSession?.pausedAt ?? .now
        updateTicker()
    }

    @discardableResult
    func startTimer(
        project: Project,
        note: String?,
        tags: [String],
        customHourlyRate: Decimal?,
        startDate: Date? = nil
    ) throws -> WorkSession {
        let persistedActiveSessions = try sessionRepository.fetchActiveSessions()

        guard activeSession == nil, persistedActiveSessions.isEmpty else {
            throw TimerServiceError.activeTimerAlreadyExists
        }

        let sessionStartDate = startDate ?? .now
        let settings = try settingsRepository.fetchOrCreateSettings()
        let resolvedRate = sessionCalculator.resolvedRate(
            sessionCustomRate: customHourlyRate,
            projectRate: project.hourlyRate,
            defaultRate: settings.defaultHourlyRate
        )

        let session = WorkSession(
            project: project,
            startTime: sessionStartDate,
            endTime: nil,
            durationSeconds: 0,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            tags: tags,
            customHourlyRate: customHourlyRate,
            resolvedHourlyRateSnapshot: resolvedRate,
            createdAt: sessionStartDate,
            updatedAt: sessionStartDate
        )

        try sessionRepository.insert(session)
        activeSession = session
        currentDate = sessionStartDate
        updateTicker()
        return session
    }

    @discardableResult
    func stopActiveTimer(at endDate: Date = .now) throws -> WorkSession {
        guard let session = activeSession else {
            throw TimerServiceError.noActiveTimer
        }

        currentDate = endDate
        let settings = try settingsRepository.fetchOrCreateSettings()
        session.endTime = endDate
        session.durationSeconds = sessionCalculator.billableDurationSeconds(
            rawDurationSeconds: elapsedDuration(for: session, at: endDate),
            roundingMode: SessionCalculator.RoundingMode(rawValue: settings.roundingMode) ?? .none,
            roundingMinutes: settings.roundingMinutes
        )
        session.pausedAt = nil
        session.updatedAt = endDate

        try sessionRepository.save()
        activeSession = nil
        updateTicker()

        return session
    }

    @discardableResult
    func pauseActiveTimer(at pauseDate: Date = .now) throws -> WorkSession {
        guard let session = activeSession else {
            throw TimerServiceError.noActiveTimer
        }

        guard session.isPaused == false else {
            throw TimerServiceError.timerAlreadyPaused
        }

        session.pausedAt = pauseDate
        session.updatedAt = pauseDate
        currentDate = pauseDate

        try sessionRepository.save()
        updateTicker()
        return session
    }

    @discardableResult
    func resumeActiveTimer(at resumeDate: Date = .now) throws -> WorkSession {
        guard let session = activeSession else {
            throw TimerServiceError.noActiveTimer
        }

        guard let pausedAt = session.pausedAt else {
            throw TimerServiceError.timerIsNotPaused
        }

        session.accumulatedPausedSeconds += max(0, resumeDate.timeIntervalSince(pausedAt))
        session.pausedAt = nil
        session.updatedAt = resumeDate
        currentDate = resumeDate

        try sessionRepository.save()
        updateTicker()
        return session
    }

    @discardableResult
    func updateActiveSessionRate(customHourlyRate: Decimal?, updatedAt: Date = .now) throws -> WorkSession {
        guard let session = activeSession else {
            throw TimerServiceError.noActiveTimer
        }

        let settings = try settingsRepository.fetchOrCreateSettings()
        session.customHourlyRate = customHourlyRate
        session.resolvedHourlyRateSnapshot = sessionCalculator.resolvedRate(
            sessionCustomRate: customHourlyRate,
            projectRate: session.project?.hourlyRate,
            defaultRate: settings.defaultHourlyRate
        )
        session.updatedAt = updatedAt

        try sessionRepository.save()
        return session
    }

    func elapsedDuration(for session: WorkSession, at currentDate: Date? = nil) -> TimeInterval {
        let referenceDate = currentDate ?? self.currentDate
        let effectiveEndDate = session.pausedAt ?? session.endTime ?? referenceDate
        let rawDuration = max(0, effectiveEndDate.timeIntervalSince(session.startTime))
        return max(0, rawDuration - session.accumulatedPausedSeconds)
    }

    private func updateTicker() {
        tickerTask?.cancel()

        guard let activeSession, activeSession.isPaused == false else {
            return
        }

        tickerTask = Task { @MainActor [weak self] in
            guard let self else { return }

            while Task.isCancelled == false {
                currentDate = .now

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    break
                }
            }
        }
    }
}
