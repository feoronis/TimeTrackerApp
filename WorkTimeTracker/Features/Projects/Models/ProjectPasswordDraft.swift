import Foundation

struct ProjectPasswordDraft {
    var title = ""
    var password = ""
    var itemDescription = ""
    var groupName = ""

    init() {}

    init(item: ProjectPasswordItem) {
        title = item.title
        password = item.password
        itemDescription = item.itemDescription ?? ""
        groupName = item.groupName
    }
}
