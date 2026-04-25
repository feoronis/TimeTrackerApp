import SwiftUI

struct ReportSummaryCards: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        let summary = viewModel.report?.summary

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.lg),
                GridItem(.flexible(), spacing: AppSpacing.lg),
                GridItem(.flexible(), spacing: AppSpacing.lg)
            ],
            spacing: AppSpacing.lg
        ) {
            SummaryMetricCard(
                title: "Общее время",
                value: AppFormatters.durationText(from: summary?.totalDurationSeconds ?? 0),
                subtitle: "Все сессии за период"
            )

            SummaryMetricCard(
                title: "Общий доход",
                value: AppFormatters.currencyText(summary?.totalIncome ?? .zero, currencyCode: viewModel.currencyCode),
                subtitle: "Сумма доходов по сессиям"
            )

            SummaryMetricCard(
                title: "Рабочие дни",
                value: "\(summary?.workDaysCount ?? 0)",
                subtitle: "Уникальные дни с активностью"
            )

            SummaryMetricCard(
                title: "Количество сессий",
                value: "\(summary?.sessionCount ?? 0)",
                subtitle: "Все записи периода"
            )

            SummaryMetricCard(
                title: "Среднее время в день",
                value: AppFormatters.durationText(from: summary?.averageDurationPerWorkDay ?? 0),
                subtitle: "На один рабочий день"
            )

            SummaryMetricCard(
                title: "Средний доход в день",
                value: AppFormatters.currencyText(summary?.averageIncomePerWorkDay ?? .zero, currencyCode: viewModel.currencyCode),
                subtitle: "На один рабочий день"
            )

            SummaryMetricCard(
                title: "Самый прибыльный проект",
                value: summary?.mostProfitableProjectName ?? "Нет данных",
                subtitle: "Лидер по доходу"
            )

            SummaryMetricCard(
                title: "Самый длинный проект",
                value: summary?.longestProjectName ?? "Нет данных",
                subtitle: "Лидер по времени"
            )
        }
    }
}
