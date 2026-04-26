import Foundation
import Observation

enum ProjectDetailTab: String, CaseIterable, Identifiable {
    case general
    case passwords

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "Основное"
        case .passwords:
            return "Пароли"
        }
    }

    var iconName: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .passwords:
            return "lock.shield"
        }
    }
}

struct ProjectPasswordGroupSection: Identifiable, Equatable {
    let id: String
    let title: String
    let items: [ProjectPasswordItem]
}

@MainActor
@Observable
final class ProjectDetailViewModel {
    private let appEnvironment: AppEnvironment
    private let projectRepository: ProjectRepository
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let passwordService: ProjectPasswordService

    private(set) var project: Project?
    private(set) var settings: AppSettings?
    private(set) var passwordItems: [ProjectPasswordItem] = []
    private let initialProjectID: UUID?

    var draft: ProjectDraft
    var selectedTab: ProjectDetailTab = .general
    var errorMessage: String?
    var successMessage: String?
    var isDeleteConfirmationPresented = false
    var isPasswordDeleteConfirmationPresented = false
    var isPasswordEditorPresented = false
    var passwordSearchText = ""
    var selectedGroupFilter: String?
    var passwordEditorDraft = ProjectPasswordDraft()
    var editingPasswordID: UUID?
    var revealedPasswordIDs = Set<UUID>()
    var passwordPendingDeletion: ProjectPasswordItem?

    init(appEnvironment: AppEnvironment, project: Project?, selectedTab: ProjectDetailTab = .general) {
        self.appEnvironment = appEnvironment
        self.projectRepository = appEnvironment.projectRepository
        self.sessionRepository = appEnvironment.sessionRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.passwordService = appEnvironment.projectPasswordService
        self.project = project
        self.initialProjectID = project?.id
        self.draft = project.map(ProjectDraft.init(project:)) ?? ProjectDraft()
        self.selectedTab = selectedTab
    }

    var colorOptions: [String] {
        ["#7C5CFF", "#5B7CFA", "#5CC47D", "#FFB86B", "#FF7A7A", "#FF7AC3", "#9CA3AF"]
    }

    var iconOptions: [String] {
        ["folder", "hammer", "desktopcomputer", "iphone", "paintpalette", "globe", "cart", "briefcase"]
    }

    var isEditingExistingProject: Bool {
        project != nil
    }

    var projectID: UUID? {
        project?.id
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var existingGroupNames: [String] {
        Array(
            Set(
                passwordItems
                    .map { $0.groupName.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false && $0 != "Без группы" }
            )
        )
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var groupedPasswords: [ProjectPasswordGroupSection] {
        let trimmedSearch = passwordSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredItems = passwordItems.filter { item in
            if let selectedGroupFilter,
               item.groupName.localizedCaseInsensitiveCompare(selectedGroupFilter) != .orderedSame {
                return false
            }

            guard trimmedSearch.isEmpty == false else { return true }

            return item.title.localizedCaseInsensitiveContains(trimmedSearch)
                || item.groupName.localizedCaseInsensitiveContains(trimmedSearch)
        }

        let groups = Dictionary(grouping: filteredItems) { item in
            let trimmedGroupName = item.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedGroupName.isEmpty ? "Без группы" : trimmedGroupName
        }

        return groups
            .map { key, value in
                ProjectPasswordGroupSection(
                    id: key,
                    title: key,
                    items: value.sorted { lhs, rhs in
                        if lhs.updatedAt != rhs.updatedAt {
                            return lhs.updatedAt > rhs.updatedAt
                        }

                        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                    }
                )
            }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    func load() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()

            if let initialProjectID {
                project = try projectRepository.fetchAll().first(where: { $0.id == initialProjectID })
                if let project {
                    draft = ProjectDraft(project: project)
                }
            }

            try reloadPasswords()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func saveProject() -> UUID? {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            errorMessage = "Название проекта обязательно."
            return nil
        }

        let hourlyRate = parseOptionalDecimal(draft.hourlyRateText)

        guard draft.hourlyRateText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hourlyRate != nil else {
            errorMessage = "Ставка должна быть числом."
            return nil
        }

        do {
            if let project {
                project.name = trimmedName
                project.colorHex = normalizedHex(draft.colorHex)
                project.iconName = draft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                project.hourlyRate = hourlyRate
                project.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                project.isArchived = draft.isArchived
                project.updatedAt = .now
                try projectRepository.save()
                errorMessage = nil
                successMessage = "Изменения проекта сохранены."
                appEnvironment.notifyDataChanged()
                return project.id
            }

            let newProject = Project(
                name: trimmedName,
                colorHex: normalizedHex(draft.colorHex),
                iconName: draft.iconName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                hourlyRate: hourlyRate,
                isArchived: draft.isArchived,
                notes: draft.notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
            try projectRepository.insert(newProject)
            project = newProject
            errorMessage = nil
            successMessage = "Проект создан."
            appEnvironment.notifyDataChanged()
            load()
            return newProject.id
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func deleteProject() -> UUID? {
        guard let project else {
            return nil
        }

        do {
            let linkedSessions = try sessionRepository.fetchSessions(projectID: project.id)
            try sessionRepository.delete(linkedSessions)
            try passwordService.deleteAll(projectID: project.id)
            try projectRepository.delete(project)
            try appEnvironment.timerService.restoreActiveSessionIfNeeded()
            let deletedProjectID = project.id
            self.project = nil
            errorMessage = nil
            successMessage = nil
            appEnvironment.notifyDataChanged()
            return deletedProjectID
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func presentCreatePasswordEditor() {
        guard project != nil else {
            errorMessage = "Сначала сохраните проект, затем добавьте пароли."
            return
        }

        passwordEditorDraft = ProjectPasswordDraft()
        editingPasswordID = nil
        isPasswordEditorPresented = true
    }

    func presentEditPasswordEditor(_ item: ProjectPasswordItem) {
        passwordEditorDraft = ProjectPasswordDraft(item: item)
        editingPasswordID = item.id
        isPasswordEditorPresented = true
    }

    func requestDeletePassword(_ item: ProjectPasswordItem) {
        passwordPendingDeletion = item
        isPasswordDeleteConfirmationPresented = true
    }

    func deletePendingPassword() {
        guard let item = passwordPendingDeletion else {
            return
        }

        do {
            try passwordService.delete(itemID: item.id)
            passwordPendingDeletion = nil
            isPasswordDeleteConfirmationPresented = false
            revealedPasswordIDs.remove(item.id)
            try reloadPasswords()
            successMessage = "Запись пароля удалена."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func savePassword() {
        guard let projectID else {
            errorMessage = "Сначала сохраните проект, затем добавьте пароли."
            return
        }

        let trimmedTitle = passwordEditorDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = passwordEditorDraft.password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGroupName = passwordEditorDraft.groupName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTitle.isEmpty == false else {
            errorMessage = "Название записи обязательно."
            return
        }

        guard trimmedPassword.isEmpty == false else {
            errorMessage = "Пароль обязателен."
            return
        }

        do {
            let current = editingPasswordID.flatMap { id in
                passwordItems.first { $0.id == id }
            }
            let item = ProjectPasswordItem(
                id: current?.id ?? UUID(),
                projectID: projectID,
                title: trimmedTitle,
                accessDetails: trimmedTitle,
                password: trimmedPassword,
                itemDescription: passwordEditorDraft.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                groupName: trimmedGroupName.isEmpty ? "Без группы" : trimmedGroupName,
                createdAt: current?.createdAt ?? .now,
                updatedAt: .now
            )
            try passwordService.upsert(item)
            isPasswordEditorPresented = false
            editingPasswordID = nil
            try reloadPasswords()
            successMessage = current == nil ? "Пароль сохранён." : "Запись пароля обновлена."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportPasswords() {
        guard let project else {
            errorMessage = "Сначала сохраните проект, затем экспортируйте пароли."
            return
        }

        do {
            _ = try passwordService.exportPasswords(projectID: project.id, projectName: project.name)
            successMessage = "Файл с паролями экспортирован отдельно."
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func togglePasswordVisibility(for itemID: UUID) {
        if revealedPasswordIDs.contains(itemID) {
            revealedPasswordIDs.remove(itemID)
        } else {
            revealedPasswordIDs.insert(itemID)
        }
    }

    func toggleGroupFilter(_ groupName: String?) {
        if selectedGroupFilter == groupName {
            selectedGroupFilter = nil
        } else {
            selectedGroupFilter = groupName
        }
    }

    func isPasswordVisible(_ itemID: UUID) -> Bool {
        revealedPasswordIDs.contains(itemID)
    }

    private func reloadPasswords() throws {
        guard let projectID else {
            passwordItems = []
            revealedPasswordIDs.removeAll()
            return
        }

        passwordItems = try passwordService.fetchPasswords(projectID: projectID)
        revealedPasswordIDs = revealedPasswordIDs.intersection(Set(passwordItems.map(\.id)))
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
            return "#7C5CFF"
        }

        return trimmedValue.hasPrefix("#") ? trimmedValue : "#\(trimmedValue)"
    }
}
