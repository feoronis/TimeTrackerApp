import Foundation
import Observation

enum TimerServiceError: LocalizedError {
    case activeTimerAlreadyExists
    case multipleActiveTimersDetected
    case noActiveTimer

    var errorDescription: String? {
        switch self {
        case .activeTimerAlreadyExists:
            return "Одновременно может работать только один таймер."
        case .multipleActiveTimersDetected:
            return "Обнаружено несколько активных таймеров. Сначала разберите сохраненные сессии."
        case .noActiveTimer:
            return "Нет активного таймера для остановки."
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
        currentDate = .now
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

        let sessionStartDate = startDate ?? currentDate
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
        session.endTime = endDate
        session.durationSeconds = sessionCalculator.durationSeconds(
            start: session.startTime,
            end: endDate
        )
        session.updatedAt = endDate

        try sessionRepository.save()
        activeSession = nil
        updateTicker()

        return session
    }

    private func updateTicker() {
        tickerTask?.cancel()

        guard activeSession != nil else {
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
