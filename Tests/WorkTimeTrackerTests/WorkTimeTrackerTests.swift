import Testing
@testable import WorkTimeTracker

@Test
func projectBootstrapDefaultsAreValid() {
    let project = Project(name: "Базовый проект")
    #expect(project.name == "Базовый проект")
    #expect(project.isArchived == false)
}
