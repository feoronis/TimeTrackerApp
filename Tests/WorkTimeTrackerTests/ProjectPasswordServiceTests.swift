import Foundation
import SwiftData
import Testing
@testable import WorkTimeTracker

@MainActor
struct ProjectPasswordServiceTests {
    @Test
    func serviceStoresMetadataOutsideSnapshotAndFiltersByProject() throws {
        let context = try ProjectPasswordTestContext()
        let firstProjectID = UUID()
        let secondProjectID = UUID()

        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: firstProjectID,
                title: "Прод",
                accessDetails: "deploy / ssh",
                password: "super-secret-1",
                itemDescription: "Основной доступ",
                groupName: "Инфраструктура"
            )
        )
        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: secondProjectID,
                title: "CRM",
                accessDetails: "sales@example.com",
                password: "super-secret-2",
                itemDescription: nil,
                groupName: "Клиент"
            )
        )

        let firstProjectItems = try context.passwordService.fetchPasswords(projectID: firstProjectID)
        let rawMetadata = try String(contentsOf: context.metadataFileURL, encoding: .utf8)

        #expect(firstProjectItems.count == 1)
        #expect(firstProjectItems.first?.password == "super-secret-1")
        #expect(rawMetadata.contains("super-secret-1") == false)
        #expect(rawMetadata.contains("super-secret-2") == false)
    }

    @Test
    func exportContainsOnlyRequestedProjectPasswords() throws {
        let context = try ProjectPasswordTestContext()
        let firstProjectID = UUID()
        let secondProjectID = UUID()

        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: firstProjectID,
                title: "Прод",
                accessDetails: "deploy / ssh",
                password: "secret-exported",
                itemDescription: nil,
                groupName: "Инфраструктура"
            )
        )
        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: secondProjectID,
                title: "CRM",
                accessDetails: "sales@example.com",
                password: "secret-hidden",
                itemDescription: nil,
                groupName: "Клиент"
            )
        )

        let exportURL = try context.passwordService.exportPasswords(projectID: firstProjectID, projectName: "TimeTrack")
        let payload = try JSONDecoder.snapshotDecoder.decode(
            ProjectPasswordExportPayload.self,
            from: Data(contentsOf: exportURL)
        )

        #expect(payload.projectID == firstProjectID)
        #expect(payload.items.count == 1)
        #expect(payload.items.first?.password == "secret-exported")
    }

    @Test
    func detailViewModelGroupsPasswordsAndKeepsThemHiddenByDefault() throws {
        let context = try ProjectPasswordFeatureTestContext()
        let project = Project(name: "Клиент A")
        try context.environment.projectRepository.insert(project)

        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: project.id,
                title: "Прод-сервер",
                accessDetails: "deploy / ssh",
                password: "prod-password",
                itemDescription: nil,
                groupName: "Инфраструктура"
            )
        )
        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: project.id,
                title: "Метрика",
                accessDetails: "imap.example.com / 993 / reader@example.com",
                password: "metric-password",
                itemDescription: nil,
                groupName: "Инфраструктура"
            )
        )

        let viewModel = ProjectDetailViewModel(appEnvironment: context.environment, project: project)
        viewModel.load()

        #expect(viewModel.groupedPasswords.count == 1)
        #expect(viewModel.groupedPasswords.first?.items.count == 2)
        #expect(viewModel.isPasswordVisible(viewModel.groupedPasswords[0].items[0].id) == false)

        viewModel.togglePasswordVisibility(for: viewModel.groupedPasswords[0].items[0].id)

        #expect(viewModel.isPasswordVisible(viewModel.groupedPasswords[0].items[0].id))
    }

    @Test
    func projectsViewModelSelectsSavedProjectAfterCreateFlow() throws {
        let context = try ProjectPasswordFeatureTestContext()
        let project = Project(name: "Новый проект")
        try context.environment.projectRepository.insert(project)

        let viewModel = ProjectsViewModel(appEnvironment: context.environment)
        viewModel.presentCreateDetail()
        viewModel.handleProjectSaved(projectID: project.id)

        #expect(viewModel.destination == .project(project.id))
    }

    @Test
    func regularSnapshotDoesNotContainPasswords() throws {
        let context = try ProjectPasswordFeatureTestContext()
        let project = Project(name: "Проект без утечки")
        try context.environment.projectRepository.insert(project)

        try context.passwordService.upsert(
            ProjectPasswordItem(
                projectID: project.id,
                title: "CRM",
                accessDetails: "owner@example.com",
                password: "must-not-appear",
                itemDescription: nil,
                groupName: "Клиент"
            )
        )

        let snapshot = try context.environment.exportService.buildSnapshot()
        let snapshotData = try JSONEncoder.snapshotEncoder.encode(snapshot)
        let snapshotText = String(decoding: snapshotData, as: UTF8.self)

        #expect(snapshotText.contains("must-not-appear") == false)
    }
}

@MainActor
private struct ProjectPasswordTestContext {
    let passwordService: ProjectPasswordService
    let metadataFileURL: URL

    init() throws {
        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectPasswordServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        let exportDirectory = rootDirectory.appendingPathComponent("exports", isDirectory: true)
        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)

        passwordService = ProjectPasswordService(
            secretStore: InMemoryPasswordSecretStore(),
            applicationSupportDirectoryProvider: { rootDirectory },
            exportSaver: { data, fileName in
                let url = exportDirectory.appendingPathComponent(fileName)
                try data.write(to: url, options: .atomic)
                return url
            }
        )
        metadataFileURL = rootDirectory
            .appendingPathComponent("TimeTrack", isDirectory: true)
            .appendingPathComponent("ProjectPasswords", isDirectory: true)
            .appendingPathComponent("project-passwords.json")
    }
}

@MainActor
private struct ProjectPasswordFeatureTestContext {
    let container: ModelContainer
    let environment: AppEnvironment
    let passwordService: ProjectPasswordService

    init() throws {
        let schema = Schema([
            Project.self,
            WorkSession.self,
            AppSettings.self,
            DayNote.self,
            Tag.self
        ])
        let configuration = ModelConfiguration(
            "WorkTimeTrackerProjectPasswordTests",
            schema: schema,
            isStoredInMemoryOnly: true
        )
        container = try ModelContainer(for: schema, configurations: [configuration])

        let rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProjectPasswordFeatureTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

        passwordService = ProjectPasswordService(
            secretStore: InMemoryPasswordSecretStore(),
            applicationSupportDirectoryProvider: { rootDirectory },
            exportSaver: { data, fileName in
                let url = rootDirectory.appendingPathComponent(fileName)
                try data.write(to: url, options: .atomic)
                return url
            }
        )
        environment = AppEnvironment(modelContainer: container, projectPasswordService: passwordService)
    }
}

private final class InMemoryPasswordSecretStore: ProjectPasswordSecretStore {
    private var passwords: [UUID: String] = [:]

    func password(for id: UUID) throws -> String? {
        passwords[id]
    }

    func savePassword(_ password: String, for id: UUID) throws {
        passwords[id] = password
    }

    func deletePassword(for id: UUID) throws {
        passwords.removeValue(forKey: id)
    }
}
