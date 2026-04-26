import SwiftUI

struct ReportSummaryCards: View {
    @Bindable var viewModel: ReportsViewModel

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.lg), count: 5),
            spacing: AppSpacing.lg
        ) {
            ForEach(viewModel.summaryCards) { item in
                ReportsSummaryMetricCard(item: item)
            }
        }
    }
}

private struct ReportsSummaryMetricCard: View {
    let item: ReportsSummaryCardItem
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.md) {
            AppBundleIcon(
                name: item.iconAssetName,
                size: 73,
                color: AppColors.primaryText,
                rendersAsTemplate: false
            )
            .frame(height: 73)

            Text(item.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .frame(height: 18)

            Text(item.value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 58, alignment: .center)

            HStack(alignment: .center, spacing: AppSpacing.xs) {
                Image(systemName: item.trendDirection.symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(item.trendDirection.color)

                Text(item.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(item.trendDirection == .neutral ? AppColors.secondaryText : item.trendDirection.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(minHeight: 34, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220, alignment: .top)
        .padding(20)
        .background(AppColors.cardSecondaryFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.tableBorder, lineWidth: 1)
        }
        .shadow(color: AppColors.subtleShadow.opacity(0.9), radius: 10, y: 5)
        .contentTransition(.interpolate)
        .scaleEffect(isVisible ? 1 : 0.98)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 8)
        .animation(.smooth(duration: 0.32), value: item.value)
        .onAppear {
            withAnimation(.smooth(duration: 0.32)) {
                isVisible = true
            }
        }
        .onChange(of: item.value) {
            withAnimation(.smooth(duration: 0.28)) {
                isVisible = true
            }
        }
    }
}

struct ReportsProjectsTable: View {
    @Bindable var viewModel: ReportsViewModel
    @State private var animateIn = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("По проектам")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                if let rows = viewModel.report?.projectRows, rows.isEmpty == false {
                    ReportsProjectsHeader()

                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            ReportsProjectTableRow(row: row, currencyCode: viewModel.currencyCode)
                                .transition(.move(edge: .top).combined(with: .opacity))

                            if row.id != rows.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(AppColors.tableFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(AppColors.tableBorder, lineWidth: 1)
                    }
                    .animation(.smooth(duration: 0.30), value: rows.map(\.id))
                } else {
                    EmptyStateView(
                        title: "Нет данных за период",
                        message: "Измените период или добавьте новые сессии.",
                        systemImage: "chart.bar"
                    )
                    .frame(minHeight: 180)
                }
            }
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 10)
        .onAppear {
            withAnimation(.smooth(duration: 0.34)) {
                animateIn = true
            }
        }
        .onChange(of: viewModel.report?.projectRows.map(\.id) ?? []) {
            withAnimation(.smooth(duration: 0.30)) {
                animateIn = true
            }
        }
    }
}

private struct ReportsProjectsHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("Проект").frame(maxWidth: .infinity, alignment: .leading)
            Text("Время").frame(width: 96, alignment: .trailing)
            Text("Сессии").frame(width: 72, alignment: .trailing)
            Text("Средняя ставка").frame(width: 124, alignment: .trailing)
            Text("Сумма").frame(width: 120, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColors.secondaryText)
        .padding(.horizontal, 16)
    }
}

private struct ReportsProjectTableRow: View {
    let row: ProjectReportRow
    let currencyCode: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                ProjectDot(colorHex: row.projectColorHex ?? "#7C5CFF", size: 12)
                Text(row.projectName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(AppFormatters.compactDurationText(from: row.totalDurationSeconds))
                .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 96, alignment: .trailing)

            Text("\(row.sessionCount)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 72, alignment: .trailing)

            Text(AppFormatters.currencyText(row.averageInformationalRate, currencyCode: currencyCode) + "/ч")
                .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 124, alignment: .trailing)

            Text(AppFormatters.currencyText(row.income, currencyCode: currencyCode))
                .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
}
