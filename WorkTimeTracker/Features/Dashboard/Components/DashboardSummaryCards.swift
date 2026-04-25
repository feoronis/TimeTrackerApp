import SwiftUI

struct DashboardSummaryCards: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 4),
            spacing: AppSpacing.lg
        ) {
            DashboardMetricCard(
                title: "Отработано сегодня",
                value: viewModel.todayWorkedTimeText,
                subtitle: viewModel.todayWorkedDeltaText,
                systemImage: "clock"
            )

            DashboardMetricCard(
                title: "Доход сегодня",
                value: viewModel.todayIncomeText,
                subtitle: viewModel.todayIncomeDeltaText,
                systemImage: "rublesign.circle"
            )

            DashboardMetricCard(
                title: "Кол-во сессий",
                value: viewModel.todaySessionCountText,
                subtitle: viewModel.todaySessionDeltaText,
                systemImage: "chart.bar.doc.horizontal"
            )

            DashboardMetricCard(
                title: "Самый активный проект",
                value: viewModel.mostActiveProjectText,
                subtitle: viewModel.mostActiveProjectDurationText,
                systemImage: "folder"
            )
        }
    }
}

private struct DashboardMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.system(size: 26, weight: .semibold))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: AppSpacing.sm)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .background(AppColors.statIconBackground, in: Circle())
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
        }
    }
}
