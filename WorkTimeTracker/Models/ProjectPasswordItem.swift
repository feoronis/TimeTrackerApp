import Foundation

struct ProjectPasswordItem: Identifiable, Codable, Equatable {
    let id: UUID
    let projectID: UUID
    var title: String
    var accessDetails: String
    var password: String
    var itemDescription: String?
    var groupName: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        projectID: UUID,
        title: String,
        accessDetails: String,
        password: String,
        itemDescription: String? = nil,
        groupName: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.accessDetails = accessDetails
        self.password = password
        self.itemDescription = itemDescription
        self.groupName = groupName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case projectID
        case title
        case accessDetails
        case username
        case password
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
        password = try container.decode(String.self, forKey: .password)
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
        try container.encode(password, forKey: .password)
        try container.encodeIfPresent(itemDescription, forKey: .itemDescription)
        try container.encode(groupName, forKey: .groupName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct ProjectPasswordExportPayload: Codable {
    let version: Int
    let exportedAt: Date
    let projectID: UUID
    let items: [ProjectPasswordItem]

    init(
        version: Int = 1,
        exportedAt: Date = .now,
        projectID: UUID,
        items: [ProjectPasswordItem]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.projectID = projectID
        self.items = items
    }
}
