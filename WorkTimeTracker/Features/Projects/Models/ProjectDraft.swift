import Foundation

struct ProjectDraft {
    var name = ""
    var colorHex = "#4C8BF5"
    var iconName = "folder"
    var hourlyRateText = ""
    var notes = ""

    init() {}

    init(project: Project) {
        name = project.name
        colorHex = project.colorHex
        iconName = project.iconName ?? "folder"
        hourlyRateText = project.hourlyRate.map { "\($0)" } ?? ""
        notes = project.notes ?? ""
    }
}
