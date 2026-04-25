import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case calendar
    case reports
    case projects
    case sessions
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .calendar:
            return "Calendar"
        case .reports:
            return "Reports"
        case .projects:
            return "Projects"
        case .sessions:
            return "Sessions"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            return "square.grid.2x2"
        case .calendar:
            return "calendar"
        case .reports:
            return "chart.bar"
        case .projects:
            return "folder"
        case .sessions:
            return "clock"
        case .settings:
            return "gearshape"
        }
    }
}

struct AppRouterView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @State private var selection: AppSection = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            AppSidebar(selection: $selection)
                .frame(width: 280)

            Divider()

            Group {
                switch selection {
                case .dashboard:
                    DashboardView {
                        selection = .sessions
                    }
                case .calendar:
                    CalendarView()
                case .reports:
                    ReportsView()
                case .projects:
                    ProjectsView()
                case .sessions:
                    SessionsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.windowBackground.ignoresSafeArea())
        }
        .background(AppColors.sidebarBackground.ignoresSafeArea())
        .task {
            appEnvironment.bootstrap()
        }
    }
}

private struct AppSidebar: View {
    @Binding var selection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            HStack(spacing: AppSpacing.md) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.58, blue: 0.98),
                                Color(red: 0.21, green: 0.82, blue: 0.75)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "timer")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }

                Text("TimeTrack")
                    .font(.title3.weight(.semibold))
            }
            .padding(.top, AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                ForEach(AppSection.allCases) { section in
                    SidebarItem(
                        section: section,
                        isSelected: selection == section,
                        action: { selection = section }
                    )
                }
            }

            Spacer()

            SidebarProfileCard()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.xl)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: section.systemImage)
                    .frame(width: 18)

                Text(section.title)
                    .font(.headline)

                Spacer()
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 14)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(AppColors.glassHighlight.opacity(isSelected ? 0.26 : 0), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.sidebarSelectionTop, AppColors.sidebarSelectionBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(isHovered ? AppColors.sidebarHover : Color.clear)
    }
}

private struct SidebarProfileCard: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(Color(red: 0.36, green: 0.63, blue: 0.98))
                .frame(width: 42, height: 42)
                .overlay {
                    Text("А")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Алексей")
                    .font(.headline)

                Text("Pro Plan")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(AppColors.glassHighlight.opacity(0.18), lineWidth: 1)
        }
    }
}
