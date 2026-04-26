import AppKit
import Foundation
import Security
import UniformTypeIdentifiers

enum ProjectPasswordServiceError: LocalizedError {
    case itemNotFound
    case missingSecret
    case metadataCorrupted
    case exportCancelled
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Запись пароля не найдена."
        case .missingSecret:
            return "Не удалось прочитать сохраненный пароль."
        case .metadataCorrupted:
            return "Хранилище паролей повреждено."
        case .exportCancelled:
            return "Экспорт паролей отменен."
        case .keychainError:
            return "Не удалось сохранить пароль в защищённое хранилище macOS."
        }
    }
}

protocol ProjectPasswordSecretStore {
    func password(for id: UUID) throws -> String?
    func savePassword(_ password: String, for id: UUID) throws
    func deletePassword(for id: UUID) throws
}

struct KeychainProjectPasswordSecretStore: ProjectPasswordSecretStore {
    private let primaryServiceName: String
    private let fallbackServiceNames: [String]

    init(
        primaryServiceName: String = "TimeTrack.ProjectPasswords",
        fallbackServiceNames: [String]? = nil,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.primaryServiceName = primaryServiceName

        if let fallbackServiceNames {
            self.fallbackServiceNames = fallbackServiceNames
        } else {
            var services: [String] = []
            if let bundleIdentifier, bundleIdentifier.isEmpty == false {
                services.append("\(bundleIdentifier).project-passwords")
            }
            services.append("TimeTrack.ProjectPasswords.project-passwords")
            self.fallbackServiceNames = services.filter { $0 != primaryServiceName }
        }
    }

    func password(for id: UUID) throws -> String? {
        if let password = try readPassword(for: id, serviceName: primaryServiceName) {
            return password
        }

        for serviceName in fallbackServiceNames {
            guard let password = try readPassword(for: id, serviceName: serviceName) else {
                continue
            }

            // Migrate secret into stable service name so app updates keep access.
            try savePassword(password, for: id)
            try deletePassword(for: id, serviceName: serviceName)
            return password
        }

        if let (password, serviceName) = try readPasswordFromAnyService(for: id) {
            if serviceName != primaryServiceName {
                try savePassword(password, for: id)
                try deletePassword(for: id, serviceName: serviceName)
            }

            return password
        }

        return nil
    }

    func savePassword(_ password: String, for id: UUID) throws {
        let data = Data(password.utf8)
        let query = baseQuery(for: id, serviceName: primaryServiceName)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw ProjectPasswordServiceError.keychainError(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

        guard addStatus == errSecSuccess else {
            throw ProjectPasswordServiceError.keychainError(addStatus)
        }
    }

    func deletePassword(for id: UUID) throws {
        try deletePassword(for: id, serviceName: primaryServiceName)

        for serviceName in fallbackServiceNames {
            try deletePassword(for: id, serviceName: serviceName)
        }
    }

    private func readPassword(for id: UUID, serviceName: String) throws -> String? {
        let query = baseQuery(for: id, serviceName: serviceName)
            .merging([kSecReturnData as String: true], uniquingKeysWith: { current, _ in current })

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw ProjectPasswordServiceError.missingSecret
            }

            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw ProjectPasswordServiceError.keychainError(status)
        }
    }

    private func readPasswordFromAnyService(for id: UUID) throws -> (password: String, serviceName: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard
                let dictionary = item as? [String: Any],
                let data = dictionary[kSecValueData as String] as? Data,
                let password = String(data: data, encoding: .utf8),
                let serviceName = dictionary[kSecAttrService as String] as? String
            else {
                throw ProjectPasswordServiceError.missingSecret
            }

            return (password, serviceName)
        case errSecItemNotFound:
            return nil
        default:
            throw ProjectPasswordServiceError.keychainError(status)
        }
    }

    private func deletePassword(for id: UUID, serviceName: String) throws {
        let status = SecItemDelete(baseQuery(for: id, serviceName: serviceName) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProjectPasswordServiceError.keychainError(status)
        }
    }

    private func baseQuery(for id: UUID, serviceName: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: id.uuidString
        ]
    }
}

@MainActor
final class ProjectPasswordService {
    private let fileManager: FileManager
    private let secretStore: ProjectPasswordSecretStore
    private let metadataFileURL: URL
    private let exportSaver: (Data, String) throws -> URL

    init(
        fileManager: FileManager = .default,
        secretStore: ProjectPasswordSecretStore = KeychainProjectPasswordSecretStore(),
        applicationSupportDirectoryProvider: (() throws -> URL)? = nil,
        exportSaver: ((Data, String) throws -> URL)? = nil
    ) {
        self.fileManager = fileManager
        self.secretStore = secretStore
        let directoryProvider = applicationSupportDirectoryProvider ?? ProjectPasswordService.defaultApplicationSupportDirectory
        let directoryURL = (try? directoryProvider()) ?? fileManager.temporaryDirectory
        let passwordsDirectoryURL = directoryURL
            .appending(path: "TimeTrack", directoryHint: .isDirectory)
            .appending(path: "ProjectPasswords", directoryHint: .isDirectory)
        metadataFileURL = passwordsDirectoryURL.appending(path: "project-passwords.json")
        self.exportSaver = exportSaver ?? Self.defaultExportSaver
    }

    func fetchPasswords(projectID: UUID) throws -> [ProjectPasswordItem] {
        try loadItems()
            .filter { $0.projectID == projectID }
            .sorted {
                if $0.groupName.localizedCaseInsensitiveCompare($1.groupName) != .orderedSame {
                    return $0.groupName.localizedCaseInsensitiveCompare($1.groupName) == .orderedAscending
                }

                if $0.updatedAt != $1.updatedAt {
                    return $0.updatedAt > $1.updatedAt
                }

                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
    }

    func upsert(_ item: ProjectPasswordItem) throws {
        var items = try loadMetadata()
        let metadata = ProjectPasswordMetadata(item: item)

        try secretStore.savePassword(item.password, for: item.id)

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = metadata
        } else {
            items.append(metadata)
        }

        try saveMetadata(items)
    }

    func delete(itemID: UUID) throws {
        var items = try loadMetadata()
        guard items.contains(where: { $0.id == itemID }) else {
            throw ProjectPasswordServiceError.itemNotFound
        }

        items.removeAll { $0.id == itemID }
        try saveMetadata(items)
        try secretStore.deletePassword(for: itemID)
    }

    func deleteAll(projectID: UUID) throws {
        let items = try loadMetadata()
        let deletedIDs = items.filter { $0.projectID == projectID }.map(\.id)
        let keptItems = items.filter { $0.projectID != projectID }
        try saveMetadata(keptItems)

        for id in deletedIDs {
            try secretStore.deletePassword(for: id)
        }
    }

    func exportPasswords(projectID: UUID, projectName: String) throws -> URL {
        let items = try fetchPasswords(projectID: projectID)
        let payload = ProjectPasswordExportPayload(projectID: projectID, items: items)
        let data = try JSONEncoder.snapshotEncoder.encode(payload)
        let suggestedName = "project-passwords-\(sanitizedFileName(projectName))-\(Date.fileTimestamp).json"
        return try exportSaver(data, suggestedName)
    }

    private func loadItems() throws -> [ProjectPasswordItem] {
        let metadataItems = try loadMetadata()
        var resolvedItems: [ProjectPasswordItem] = []
        var metadataWithoutSecrets = Set<UUID>()

        for metadata in metadataItems {
            do {
                guard let password = try secretStore.password(for: metadata.id) else {
                    metadataWithoutSecrets.insert(metadata.id)
                    continue
                }

                resolvedItems.append(metadata.item(password: password))
            } catch ProjectPasswordServiceError.missingSecret {
                metadataWithoutSecrets.insert(metadata.id)
            } catch {
                throw error
            }
        }

        // Auto-heal stale metadata entries when Keychain items are gone.
        if metadataWithoutSecrets.isEmpty == false {
            let healthyMetadata = metadataItems.filter { metadataWithoutSecrets.contains($0.id) == false }
            try saveMetadata(healthyMetadata)
        }

        return resolvedItems
    }

    private func loadMetadata() throws -> [ProjectPasswordMetadata] {
        guard fileManager.fileExists(atPath: metadataFileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: metadataFileURL)
            return try JSONDecoder.snapshotDecoder.decode([ProjectPasswordMetadata].self, from: data)
        } catch {
            throw ProjectPasswordServiceError.metadataCorrupted
        }
    }

    private func saveMetadata(_ items: [ProjectPasswordMetadata]) throws {
        let directoryURL = metadataFileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try JSONEncoder.snapshotEncoder.encode(items)
        try data.write(to: metadataFileURL, options: .atomic)
    }

    private func sanitizedFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let raw = value
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
        let string = String(raw)
            .replacingOccurrences(of: "--", with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return string.isEmpty ? "project" : string
    }

    private static func defaultApplicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    private static func defaultExportSaver(_ data: Data, _ suggestedFileName: String) throws -> URL {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedFileName
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else {
            throw ProjectPasswordServiceError.exportCancelled
        }

        try data.write(to: url, options: .atomic)
        return url
    }
}

private struct ProjectPasswordMetadata: Codable {
    let id: UUID
    let projectID: UUID
    let title: String
    let accessDetails: String
    let itemDescription: String?
    let groupName: String
    let createdAt: Date
    let updatedAt: Date

    init(item: ProjectPasswordItem) {
        id = item.id
        projectID = item.projectID
        title = item.title
        accessDetails = item.accessDetails
        itemDescription = item.itemDescription
        groupName = item.groupName
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    func item(password: String) -> ProjectPasswordItem {
        ProjectPasswordItem(
            id: id,
            projectID: projectID,
            title: title,
            accessDetails: accessDetails,
            password: password,
            itemDescription: itemDescription,
            groupName: groupName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case projectID
        case title
        case accessDetails
        case username
        case itemDescription
        case groupName
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectID = try container.decode(UUID.self, forKey: .projectID)
        title = try container.decode(String.self, forKey: .title)
        accessDetails = try container.decodeIfPresent(String.self, forKey: .accessDetails)
            ?? container.decodeIfPresent(String.self, forKey: .username)
            ?? ""
        itemDescription = try container.decodeIfPresent(String.self, forKey: .itemDescription)
        groupName = try container.decode(String.self, forKey: .groupName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(projectID, forKey: .projectID)
        try container.encode(title, forKey: .title)
        try container.encode(accessDetails, forKey: .accessDetails)
        try container.encodeIfPresent(itemDescription, forKey: .itemDescription)
        try container.encode(groupName, forKey: .groupName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
