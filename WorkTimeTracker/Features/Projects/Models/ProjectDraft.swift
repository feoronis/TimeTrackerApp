import Foundation

struct ProjectDraft {
    var name = ""
    var colorHex = "#7C5CFF"
    var iconName = "folder"
    var hourlyRateText = ""
    var notes = ""
    var isArchived = false

    init() {}

    init(project: Project) {
        name = project.name
        colorHex = project.colorHex
        iconName = project.iconName ?? "folder"
        hourlyRateText = project.hourlyRate.map { "\($0)" } ?? ""
        notes = project.notes ?? ""
        isArchived = project.isArchived
    }
}
