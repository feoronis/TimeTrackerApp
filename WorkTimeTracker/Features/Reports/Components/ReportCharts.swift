import Charts
import SwiftUI

struct ReportCharts: View {
    @Bindable var viewModel: ReportsViewModel
    @State private var chartAnimationToken = UUID()

    var body: some View {
        let report = viewModel.report

        Group {
            if let report, report.summary.sessionCount > 0 {
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    ReportsLineChartCard(
                        title: report.chartGranularity == .hour ? "Доход по часам" : "Доход по дням",
                        points: makePoints(from: report.incomeByDate) {
                            ReportsLinePoint(
                                date: $0.date,
                                numericValue: NSDecimalNumber(decimal: $0.totalIncome).doubleValue,
                                displayValue: AppFormatters.currencyText($0.totalIncome, currencyCode: viewModel.currencyCode)
                            )
                        },
                        granularity: report.chartGranularity,
                        metric: .income,
                        color: AppColors.purple,
                        currencyCode: viewModel.currencyCode
                    )

                    ReportsLineChartCard(
                        title: report.chartGranularity == .hour ? "Время по часам" : "Время по дням",
                        points: makePoints(from: report.timeByDate) {
                            ReportsLinePoint(
                                date: $0.date,
                                numericValue: $0.totalDurationSeconds / 3600,
                                displayValue: AppFormatters.compactDurationText(from: $0.totalDurationSeconds)
                            )
                        },
                        granularity: report.chartGranularity,
                        metric: .time,
                        color: AppColors.blue,
                        currencyCode: viewModel.currencyCode
                    )

                    ReportsDonutChartCard(
                        title: "Время по проектам",
                        rows: report.projectRows
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(chartAnimationToken)
            } else {
                GlassCard {
                    EmptyStateView(
                        title: "Нет данных для графиков",
                        message: "Измените период или создайте больше сессии.",
                        systemImage: "chart.bar"
                    )
                    .frame(minHeight: 220)
                }
            }
        }
        .onAppear {
            chartAnimationToken = UUID()
        }
        .onChange(of: viewModel.report?.summary.sessionCount ?? 0) {
            withAnimation(.smooth(duration: 0.34)) {
                chartAnimationToken = UUID()
            }
        }
    }

    private func makePoints(
        from source: [TimeSeriesChartPoint],
        transform: (TimeSeriesChartPoint) -> ReportsLinePoint
    ) -> [ReportsLinePoint] {
        source.enumerated().map { index, item in
            var point = transform(item)
            point.isLast = index == source.index(before: source.endIndex)
            return point
        }
    }
}

private struct ReportsLineChartCard: View {
    let title: String
    let points: [ReportsLinePoint]
    let granularity: ReportChartGranularity
    let metric: ReportsLineMetric
    let color: Color
    let currencyCode: String
    @State private var isVisible = false

    private let trailingAnchorID = "chart-trailing-anchor"

    private var tickValues: [Double] {
        let maxValue = max(points.map(\.numericValue).max() ?? 0, 0)
        guard maxValue > 0 else {
            return [0]
        }

        let steps = 4
        return (0...steps).map { maxValue * Double($0) / Double(steps) }
    }

    private var chartWidth: CGFloat {
        let pointWidth = granularity == .hour ? CGFloat(72) : CGFloat(56)
        return max(360, CGFloat(points.count) * pointWidth)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                HStack(alignment: .bottom, spacing: AppSpacing.md) {
                    ReportsFixedYAxis(
                        tickValues: tickValues,
                        metric: metric,
                        currencyCode: currencyCode
                    )

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                Chart {
                                    ForEach(tickValues, id: \.self) { tickValue in
                                        RuleMark(y: .value("Шкала", tickValue))
                                            .foregroundStyle(AppColors.chartGrid)
                                    }

                                    ForEach(points) { point in
                                        AreaMark(
                                            x: .value("Дата", point.date),
                                            y: .value("Значение", point.numericValue)
                                        )
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [color.opacity(0.18), color.opacity(0.02)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .interpolationMethod(.catmullRom)

                                        LineMark(
                                            x: .value("Дата", point.date),
                                            y: .value("Значение", point.numericValue)
                                        )
                                        .foregroundStyle(color)
                                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                                        .interpolationMethod(.catmullRom)

                                        if point.isLast {
                                            PointMark(
                                                x: .value("Дата", point.date),
                                                y: .value("Значение", point.numericValue)
                                            )
                                            .foregroundStyle(color)
                                            .annotation(position: .topTrailing, spacing: 8) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(point.tooltipTitle(for: granularity))
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundStyle(AppColors.primaryText)
                                                    Text(point.displayValue)
                                                        .font(.system(size: 11, weight: .medium))
                                                        .foregroundStyle(AppColors.secondaryText)
                                                }
                                                .padding(8)
                                                .background(AppColors.tooltipFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                        .strokeBorder(AppColors.tooltipBorder, lineWidth: 1)
                                                }
                                                .shadow(color: AppColors.subtleShadow.opacity(0.9), radius: 8, y: 4)
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .automatic(desiredCount: granularity == .hour ? 6 : 8)) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                            .foregroundStyle(AppColors.chartAxis)
                                        AxisTick().foregroundStyle(Color.clear)
                                        if granularity == .hour {
                                            AxisValueLabel(format: .dateTime.hour())
                                                .foregroundStyle(AppColors.secondaryText)
                                        } else {
                                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                                                .foregroundStyle(AppColors.secondaryText)
                                        }
                                    }
                                }
                                .chartYAxis(.hidden)
                                .frame(width: chartWidth, height: 220)
                                .padding(.top, 10)

                                Color.clear
                                    .frame(width: 1, height: 1)
                                    .id(trailingAnchorID)
                            }
                        }
                        .defaultScrollAnchor(.trailing)
                        .onAppear {
                            proxy.scrollTo(trailingAnchorID, anchor: .trailing)
                        }
                        .onChange(of: points.map(\.id)) {
                            proxy.scrollTo(trailingAnchorID, anchor: .trailing)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .animation(.smooth(duration: 0.34), value: points.map(\.id))
        .onAppear {
            withAnimation(.smooth(duration: 0.34)) {
                isVisible = true
            }
        }
        .onChange(of: points.map(\.id)) {
            withAnimation(.smooth(duration: 0.30)) {
                isVisible = true
            }
        }
    }
}

private struct ReportsFixedYAxis: View {
    let tickValues: [Double]
    let metric: ReportsLineMetric
    let currencyCode: String

    var body: some View {
        VStack {
            ForEach(Array(tickValues.enumerated()).reversed(), id: \.offset) { item in
                Text(label(for: item.element))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if item.element != tickValues.first {
                    Spacer()
                }
            }
        }
        .frame(width: 72, height: 220, alignment: .trailing)
        .padding(.top, 10)
    }

    private func label(for value: Double) -> String {
        switch metric {
        case .income:
            return AppFormatters.currencyText(Decimal(value), currencyCode: currencyCode)
        case .time:
            return AppFormatters.compactDurationText(from: value * 3600)
        }
    }
}

private enum ReportsLineMetric {
    case income
    case time
}

private struct ReportsDonutChartCard: View {
    let title: String
    let rows: [ProjectReportRow]
    @State private var isVisible = false
    @State private var hoveredSegmentID: String?

    private var totalDuration: TimeInterval {
        rows.reduce(0) { $0 + $1.totalDurationSeconds }
    }

    private var segments: [ReportsDonutSegment] {
        let palette = ["#7C5CFF", "#5B7CFA", "#5CC47D", "#FFB86B", "#FF7A7A"]

        return rows.prefix(5).enumerated().map { index, row in
            let percentage = totalDuration > 0 ? row.totalDurationSeconds / totalDuration : 0
            return ReportsDonutSegment(
                name: row.projectName,
                colorHex: row.projectColorHex ?? palette[index % palette.count],
                percentage: percentage,
                totalDurationSeconds: row.totalDurationSeconds
            )
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                HStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Chart(segments) { segment in
                            SectorMark(
                                angle: .value("Доля", segment.percentage),
                                innerRadius: .ratio(0.62),
                                outerRadius: .fixed(hoveredSegmentID == segment.id ? 84 : 74)
                            )
                            .foregroundStyle(Color(hex: segment.colorHex) ?? AppColors.purple)
                            .cornerRadius(4)
                            .opacity(hoveredSegmentID == nil || hoveredSegmentID == segment.id ? 1 : 0.72)
                        }
                        .frame(width: 160, height: 160)
                        .padding(.trailing, 6)
                        .padding(.vertical, 6)
                        .rotationEffect(.degrees(isVisible ? 0 : -18))
                        .scaleEffect(isVisible ? 1 : 0.92)
                        .animation(.snappy(duration: 0.42, extraBounce: 0.03), value: isVisible)
                        .animation(.snappy(duration: 0.22, extraBounce: 0.02), value: hoveredSegmentID)

                        VStack(spacing: 4) {
                            Text(AppFormatters.compactDurationText(from: totalDuration))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AppColors.primaryText)
                            Text("Всего")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }

                    ScrollView(.vertical, showsIndicators: segments.count > 5) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(segments) { segment in
                                HStack(spacing: 8) {
                                    ProjectDot(colorHex: segment.colorHex, size: 10)
                                    Text(segment.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(AppColors.primaryText)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(Int((segment.percentage * 100).rounded()))%")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(hoveredSegmentID == segment.id ? AppColors.rowHoverFill : Color.clear)
                                )
                                .animation(.snappy(duration: 0.22, extraBounce: 0.02), value: hoveredSegmentID)
                                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .onHover { isHovering in
                                    hoveredSegmentID = isHovering ? segment.id : nil
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 220, alignment: .top)
                }
                .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.smooth(duration: 0.36)) {
                isVisible = true
            }
        }
        .onChange(of: rows.map(\.id)) {
            withAnimation(.smooth(duration: 0.32)) {
                isVisible = true
            }
        }
    }
}

private struct ReportsLinePoint: Identifiable {
    let date: Date
    let numericValue: Double
    let displayValue: String
    var isLast = false

    var id: Date { date }

    func tooltipTitle(for granularity: ReportChartGranularity) -> String {
        switch granularity {
        case .hour:
            return AppFormatters.statusTimeText(date)
        case .day:
            return AppFormatters.reportShortDateText(date)
        }
    }
}

private struct ReportsDonutSegment: Identifiable {
    let name: String
    let colorHex: String
    let percentage: Double
    let totalDurationSeconds: TimeInterval

    var id: String { name }
}
