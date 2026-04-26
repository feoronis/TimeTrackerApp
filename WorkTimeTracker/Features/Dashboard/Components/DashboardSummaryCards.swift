import SwiftUI

struct DashboardSummaryCards: View {
    @Bindable var viewModel: DashboardViewModel
    let availableWidth: CGFloat

    private var columns: [GridItem] {
        let count: Int

        switch availableWidth {
        case ..<760:
            count = 1
        case ..<1_020:
            count = 2
        default:
            count = 4
        }

        return Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: count)
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            spacing: AppSpacing.lg
        ) {
            DashboardMetricCard(
                title: "Отработано сегодня",
                value: viewModel.todayWorkedTimeText,
                subtitle: viewModel.todayWorkedDeltaText,
                systemImage: "clock",
                iconBackground: AppColors.blue.opacity(0.14),
                iconColor: AppColors.blue
            )

            DashboardMetricCard(
                title: "Доход сегодня",
                value: viewModel.todayIncomeText,
                subtitle: viewModel.todayIncomeDeltaText,
                systemImage: "rublesign.circle",
                iconBackground: AppColors.purple.opacity(0.14),
                iconColor: AppColors.purple
            )

            DashboardMetricCard(
                title: "Кол-во сессий",
                value: viewModel.todaySessionCountText,
                subtitle: viewModel.todaySessionDeltaText,
                systemImage: "chart.bar.doc.horizontal",
                iconBackground: AppColors.orange.opacity(0.18),
                iconColor: AppColors.orange
            )

            DashboardMetricCard(
                title: "Самый активный проект",
                value: viewModel.mostActiveProjectText,
                subtitle: viewModel.mostActiveProjectDurationText,
                systemImage: "folder",
                iconBackground: AppColors.pink.opacity(0.14),
                iconColor: AppColors.pink
            )
        }
        .padding(.top, AppSpacing.sm)
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String
    let iconBackground: Color
    let iconColor: Color

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                Text(value)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)

                HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: systemImage)
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 42, height: 42)
                        .background(iconBackground, in: Circle())
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
