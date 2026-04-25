import Foundation

struct SessionDraft {
    var projectID: UUID?
    var startTime: Date = .now.addingTimeInterval(-3600)
    var endTime: Date = .now
    var note = ""
    var tagsText = ""
    var customHourlyRateText = ""

    init() {}

    init(session: WorkSession) {
        projectID = session.project?.id
        startTime = session.startTime
        endTime = session.endTime ?? Date.now
        note = session.note ?? ""
        tagsText = session.tags.joined(separator: ", ")
        customHourlyRateText = session.customHourlyRate.map { AppFormatters.decimalText($0) } ?? ""
    }
}
