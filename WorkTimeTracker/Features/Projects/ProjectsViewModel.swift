import Foundation
import Observation

enum ProjectDetailDestination: Equatable {
    case create
    case project(UUID)
}

@MainActor
@Observable
final class ProjectsViewModel {
    private let projectRepository: ProjectRepository
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let sessionCalculator: SessionCalculator

    private(set) var projects: [Project] = []
    private(set) var projectRows: [ProjectListRow] = []
    private(set) var settings: AppSettings?
    var searchText = ""
    var showArchived = true
    var errorMessage: String?
    var destination: ProjectDetailDestination?
    var selectedDetailTab: ProjectDetailTab = .general

    init(appEnvironment: AppEnvironment) {
        self.projectRepository = appEnvironment.projectRepository
        self.sessionRepository = appEnvironment.sessionRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.sessionCalculator = appEnvironment.sessionCalculator
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var visibleRows: [ProjectListRow] {
        projectRows
            .filter { showArchived || $0.isArchived == false }
            .filter { row in
                let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmedSearch.isEmpty == false else { return true }
                return row.name.localizedCaseInsensitiveContains(trimmedSearch)
            }
    }

    var selectedProjectID: UUID? {
        if case let .project(projectID) = destination {
            return projectID
        }

        return nil
    }

    var selectedProject: Project? {
        guard let selectedProjectID else {
            return nil
        }

        return projects.first { $0.id == selectedProjectID }
    }

    func load() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            let sessions = try sessionRepository.fetchAll()
            projectRows = buildProjectRows(projects: projects, sessions: sessions)
            reconcileSelection()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentCreateDetail() {
        destination = .create
        errorMessage = nil
    }

    func selectProject(_ projectID: UUID) {
        destination = .project(projectID)
        errorMessage = nil
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

    func handleProjectSaved(projectID: UUID) {
        destination = .project(projectID)
        load()
    }

    func handleProjectDeleted(projectID: UUID) {
        load()
        destination = nil
    }

    private func reconcileSelection() {
        switch destination {
        case .create:
            return
        case let .project(projectID):
            if projects.contains(where: { $0.id == projectID }) == false {
                destination = nil
            }
        case nil:
            return
        }
    }

    private func buildProjectRows(projects: [Project], sessions: [WorkSession]) -> [ProjectListRow] {
        projects.map { project in
            let projectSessions = sessions.filter { $0.project?.id == project.id && $0.endTime != nil }
            let totalDuration = projectSessions.reduce(0) { $0 + $1.durationSeconds }
            let totalIncome = projectSessions.reduce(Decimal.zero) { $0 + sessionCalculator.sessionIncome($1) }

            return ProjectListRow(
                id: project.id,
                name: project.name,
                colorHex: project.colorHex,
                iconName: project.iconName ?? "folder",
                hourlyRate: project.hourlyRate,
                totalDurationSeconds: totalDuration,
                totalIncome: totalIncome,
                isArchived: project.isArchived
            )
        }
        .sorted { lhs, rhs in
            if lhs.isArchived != rhs.isArchived {
                return rhs.isArchived == false
            }
            return lhs.totalIncome > rhs.totalIncome
        }
    }
}

struct ProjectListRow: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let iconName: String
    let hourlyRate: Decimal?
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal
    let isArchived: Bool
}
