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
            return "Панель"
        case .calendar:
            return "Календарь"
        case .reports:
            return "Отчёты"
        case .projects:
            return "Проекты"
        case .sessions:
            return "Сессии"
        case .settings:
            return "Настройки"
        }
    }

    var iconName: String {
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
}

struct AppRouterView: View {
    @Environment(AppEnvironment.self) private var appEnvironment
    @State private var selection: AppSection = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            AppSidebar(selection: $selection)
                .frame(width: 244)

            Divider()

            ZStack {
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
            .id(selection)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: selection)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.windowGradient.ignoresSafeArea())
        }
        .background(AppColors.windowGradient.ignoresSafeArea())
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
                AppBundleIcon(
                    name: "logo",
                    size: 42,
                    color: AppColors.primaryText,
                    rendersAsTemplate: false
                )

                Text("TimeTrack")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.top, 4)

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
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(AppColors.sidebarGradient)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(AppColors.separator.opacity(AppearancePreferences.isDarkMode ? 1 : 0.7))
                .frame(width: 1)
        }
    }
}

private struct SidebarItem: View {
    let section: AppSection
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    private let itemHeight: CGFloat = 52
    private let selectionAnimation = Animation.easeInOut(duration: 0.18)

    var body: some View {
        Button {
            withAnimation(selectionAnimation) {
                action()
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                AppBundleIcon(
                    name: section.iconName,
                    size: 22,
                    color: itemForegroundColor
                )
                .frame(width: 22)

                Text(section.title)
                    .font(.system(size: 15, weight: .regular))

                Spacer()
            }
            .foregroundStyle(itemForegroundColor)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: itemHeight)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(isSelected ? 0.22 : 0), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var itemForegroundColor: Color {
        isSelected ? AppColors.inverseText : AppColors.primaryText
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(AppColors.primaryActionFill)
        }

        return AnyShapeStyle(isHovered ? AppColors.sidebarHover : Color.clear)
    }
}
