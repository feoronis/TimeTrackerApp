import SwiftUI

struct MenuBarTimerView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @State private var projects: [Project] = []

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            if let activeSession = appEnvironment.timerService.activeSession {
                Text(AppFormatters.durationText(from: appEnvironment.timerService.elapsedDuration(for: activeSession)))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text(activeSession.project?.name ?? "Без проекта")
                    .foregroundStyle(AppColors.secondaryText)

                HStack {
                    Button(activeSession.isPaused ? "Продолжить" : "Пауза") {
                        if activeSession.isPaused {
                            _ = try? appEnvironment.timerService.resumeActiveTimer()
                        } else {
                            _ = try? appEnvironment.timerService.pauseActiveTimer()
                        }
                        appEnvironment.notifyDataChanged()
                    }

                    Button("Остановить") {
                        _ = try? appEnvironment.timerService.stopActiveTimer()
                        appEnvironment.notifyDataChanged()
                    }
                }
            } else {
                Text("Быстрый старт")
                    .font(.headline)

                ForEach(projects.prefix(5), id: \.id) { project in
                    Button(project.name) {
                        _ = try? appEnvironment.timerService.startTimer(
                            project: project,
                            note: nil,
                            tags: [],
                            customHourlyRate: nil,
                            startDate: .now
                        )
                        appEnvironment.notifyDataChanged()
                    }
                }
            }
        }
        .padding()
        .frame(width: 240)
        .task {
            appEnvironment.bootstrap()
            reloadProjects()
        }
        .onChange(of: appEnvironment.dataChangeToken) {
            reloadProjects()
        }
    }

    private func reloadProjects() {
        projects = (try? appEnvironment.projectRepository.fetchAll(includeArchived: false)) ?? []
    }
}
