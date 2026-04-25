import Foundation
import Observation

@MainActor
@Observable
final class ProjectsViewModel {
    private let projectRepository: ProjectRepository
    private(set) var projects: [Project] = []
    var isEditorPresented = false
    var editorDraft = ProjectDraft()
    var showArchived = false
    var editingProject: Project?
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.projectRepository = appEnvironment.projectRepository
    }

    var visibleProjects: [Project] {
        showArchived ? projects : projects.filter { $0.isArchived == false }
    }

    func load() {
        do {
            projects = try projectRepository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentCreateSheet() {
        editingProject = nil
        editorDraft = ProjectDraft()
        isEditorPresented = true
    }

    func presentEditSheet(for project: Project) {
        editingProject = project
        editorDraft = ProjectDraft(project: project)
        isEditorPresented = true
    }

    func saveProject() {
        let trimmedName = editorDraft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Название проекта обязательно."
            return
        }

        let hourlyRate = parseOptionalDecimal(editorDraft.hourlyRateText)

        guard editorDraft.hourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hourlyRate != nil else {
            errorMessage = "Ставка должна быть числом."
            return
        }

        do {
            if let editingProject {
                editingProject.name = trimmedName
                editingProject.colorHex = normalizedHex(editorDraft.colorHex)
                editingProject.iconName = editorDraft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                editingProject.hourlyRate = hourlyRate
                editingProject.notes = editorDraft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                editingProject.updatedAt = .now
                try projectRepository.save()
            } else {
                let project = Project(
                    name: trimmedName,
                    colorHex: normalizedHex(editorDraft.colorHex),
                    iconName: editorDraft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    hourlyRate: hourlyRate,
                    notes: editorDraft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                )
                try projectRepository.insert(project)
            }

            isEditorPresented = false
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(_ project: Project) {
        do {
            try projectRepository.archive(project)
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unarchive(_ project: Project) {
        do {
            try projectRepository.unarchive(project)
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func parseOptionalDecimal(_ value: String) -> Decimal? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedValue.isEmpty == false else {
            return nil
        }

        return Decimal(string: trimmedValue.replacingOccurrences(of: ",", with: "."))
    }

    private func normalizedHex(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false else {
            return "#4C8BF5"
        }

        return trimmedValue.hasPrefix("#") ? trimmedValue : "#\(trimmedValue)"
    }
}
