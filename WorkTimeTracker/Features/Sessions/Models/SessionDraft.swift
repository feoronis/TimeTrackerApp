import Foundation

enum SessionDraftMode: String, CaseIterable, Identifiable {
    case timedInterval
    case completedTask

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timedInterval:
            return "Интервал"
        case .completedTask:
            return "Задача"
        }
    }
}

struct SessionDraft {
    var projectID: UUID?
    var mode: SessionDraftMode = .timedInterval
    var startTime: Date = .now.addingTimeInterval(-3600)
    var endTime: Date = .now
    var completedAt: Date = .now
    var durationHours = 1
    var durationMinutes = 0
    var note = ""
    var tagsText = ""
    var customHourlyRateText = ""
    var fixedIncomeAmountText = ""

    init() {}

    init(session: WorkSession) {
        projectID = session.project?.id
        mode = session.endTime != nil && Calendar.current.isDate(session.startTime, equalTo: session.endTime ?? session.startTime, toGranularity: .day) ? .completedTask : .timedInterval
        startTime = session.startTime
        endTime = session.endTime ?? Date.now
        completedAt = session.endTime ?? Date.now
        let totalMinutes = Int(session.durationSeconds.rounded(.down)) / 60
        durationHours = max(0, totalMinutes / 60)
        durationMinutes = max(0, totalMinutes % 60)
        note = session.note ?? ""
        tagsText = session.tags.joined(separator: ", ")
        customHourlyRateText = session.customHourlyRate.map { AppFormatters.decimalText($0) } ?? ""
        fixedIncomeAmountText = session.fixedIncomeAmount.map { AppFormatters.decimalText($0) } ?? ""
    }
}
