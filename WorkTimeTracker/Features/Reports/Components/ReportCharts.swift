import Charts
import SwiftUI

struct ReportCharts: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        let report = viewModel.report

        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Text("Графики")
                    .font(.headline)

                if let report, report.projectRows.isEmpty == false {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: AppSpacing.lg),
                            GridItem(.flexible(), spacing: AppSpacing.lg)
                        ],
                        spacing: AppSpacing.lg
                    ) {
                        ChartCard(title: "Доход по дням") {
                            Chart(report.incomeByDay) { point in
                                BarMark(
                                    x: .value("Дата", AppFormatters.shortDateText(point.date)),
                                    y: .value("Доход", NSDecimalNumber(decimal: point.totalIncome).doubleValue)
                                )
                            }
                        }

                        ChartCard(title: "Время по дням") {
                            Chart(report.timeByDay) { point in
                                BarMark(
                                    x: .value("Дата", AppFormatters.shortDateText(point.date)),
                                    y: .value("Часы", point.totalDurationSeconds / 3600)
                                )
                            }
                        }

                        ChartCard(title: "Время по проектам") {
                            Chart(report.timeByProject) { point in
                                BarMark(
                                    x: .value("Проект", point.projectName),
                                    y: .value("Часы", point.totalDurationSeconds / 3600)
                                )
                            }
                        }

                        ChartCard(title: "Доход по проектам") {
                            Chart(report.incomeByProject) { point in
                                BarMark(
                                    x: .value("Проект", point.projectName),
                                    y: .value("Доход", NSDecimalNumber(decimal: point.totalIncome).doubleValue)
                                )
                            }
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "Нет данных для графиков",
                        message: "Измените период или создайте больше сессий.",
                        systemImage: "chart.bar"
                    )
                    .frame(minHeight: 220)
                }
            }
        }
    }
}

private struct ChartCard<Content: View>: View {
    let title: String
    let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            content
                .frame(minHeight: 220)
        }
        .padding(AppSpacing.lg)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppColors.glassHighlight.opacity(0.25), lineWidth: 1)
        }
    }
}
