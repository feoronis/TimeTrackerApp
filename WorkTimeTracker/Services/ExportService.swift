import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportServiceError: LocalizedError {
    case cancelled

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Экспорт отменен."
        }
    }
}

@MainActor
struct ExportService {
    private let projectRepository: ProjectRepository
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let dayNoteRepository: DayNoteRepository
    private let tagRepository: TagRepository
    private let sessionCalculator: SessionCalculator

    init(
        projectRepository: ProjectRepository,
        sessionRepository: SessionRepository,
        settingsRepository: SettingsRepository,
        dayNoteRepository: DayNoteRepository,
        tagRepository: TagRepository,
        sessionCalculator: SessionCalculator
    ) {
        self.projectRepository = projectRepository
        self.sessionRepository = sessionRepository
        self.settingsRepository = settingsRepository
        self.dayNoteRepository = dayNoteRepository
        self.tagRepository = tagRepository
        self.sessionCalculator = sessionCalculator
    }

    func exportJSON() throws -> URL {
        let snapshot = try buildSnapshot()
        let data = try JSONEncoder.snapshotEncoder.encode(snapshot)
        return try saveData(
            data,
            suggestedFileName: "work-time-export-\(Date.fileTimestamp).json",
            allowedContentTypes: [.json]
        )
    }

    func exportCSV() throws -> URL {
        let sessions = try sessionRepository.fetchAll()
        let csv = buildCSV(from: sessions)
        let data = Data(csv.utf8)
        return try saveData(
            data,
            suggestedFileName: "work-time-sessions-\(Date.fileTimestamp).csv",
            allowedContentTypes: [.commaSeparatedText]
        )
    }

    func buildSnapshot() throws -> AppDataSnapshot {
        let settings = try settingsRepository.fetchOrCreateSettings()
        let projects = try projectRepository.fetchAll()
        let sessions = try sessionRepository.fetchAll()
        let dayNotes = try dayNoteRepository.fetchAll()
        let tags = try tagRepository.fetchAll()

        return AppDataSnapshot(
            settings: AppSettingsSnapshot(settings: settings),
            projects: projects.map(ProjectSnapshot.init(project:)),
            sessions: sessions.map(WorkSessionSnapshot.init(session:)),
            dayNotes: dayNotes.map(DayNoteSnapshot.init(dayNote:)),
            tags: tags.map(TagSnapshot.init(tag:))
        )
    }

    private func saveData(
        _ data: Data,
        suggestedFileName: String,
        allowedContentTypes: [UTType]
    ) throws -> URL {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedFileName
        panel.allowedContentTypes = allowedContentTypes

        guard panel.runModal() == .OK, let url = panel.url else {
            throw ExportServiceError.cancelled
        }

        try data.write(to: url, options: .atomic)
        return url
    }

    private func buildCSV(from sessions: [WorkSession]) -> String {
        let header = [
            "id",
            "project_name",
            "start_time",
            "end_time",
            "duration_seconds",
            "note",
            "tags",
            "custom_hourly_rate",
            "resolved_hourly_rate_snapshot",
            "fixed_income_amount",
            "session_income"
        ].joined(separator: ",")

        let rows = sessions.map { session in
            [
                session.id.uuidString,
                csvField(session.project?.name ?? "Без проекта"),
                csvField(snapshotDateString(from: session.startTime)),
                csvField(session.endTime.map(snapshotDateString(from:)) ?? ""),
                csvField(String(Int(session.durationSeconds))),
                csvField(session.note ?? ""),
                csvField(session.tags.joined(separator: "|")),
                csvField(session.customHourlyRate.map(AppFormatters.decimalText) ?? ""),
                csvField(AppFormatters.decimalText(session.resolvedHourlyRateSnapshot)),
                csvField(session.fixedIncomeAmount.map(AppFormatters.decimalText) ?? ""),
                csvField(AppFormatters.decimalText(sessionCalculator.sessionIncome(session)))
            ].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
