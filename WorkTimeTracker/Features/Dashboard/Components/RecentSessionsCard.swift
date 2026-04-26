import SwiftUI

struct RecentSessionsCard: View {
    let sessions: [WorkSession]
    let currencyCode: String
    let onShowAllSessions: (() -> Void)?
    let isCompact: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Последние сессии")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                if sessions.isEmpty {
                    EmptyStateView(
                        title: "Сессий пока нет",
                        message: "Запустите и завершите таймер, чтобы здесь появилась первая активность.",
                        systemImage: "clock.badge.questionmark"
                    )
                    .frame(minHeight: 220)
                } else {
                    VStack(spacing: 0) {
                        DashboardSessionTableHeader()

                        VStack(spacing: 0) {
                            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                                DashboardSessionRow(
                                    session: session,
                                    currencyCode: currencyCode,
                                    isFirstRow: index == 0
                                )

                                if session.id != sessions.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(AppColors.tableFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(AppColors.tableBorder, lineWidth: 1)
                        }
                    }

                    Button("Показать все сессии") {
                        onShowAllSessions?()
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.sm)
                }
            }
        }
    }
}

private enum DashboardSessionTableLayout {
    static let timeWidth: CGFloat = 88
    static let projectWidth: CGFloat = 180
    static let descriptionWidth: CGFloat = 168
    static let durationWidth: CGFloat = 88
    static let amountWidth: CGFloat = 96
}

private struct DashboardSessionTableHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            header("Время", width: DashboardSessionTableLayout.timeWidth, alignment: .leading)
            header("Проект", width: DashboardSessionTableLayout.projectWidth, alignment: .leading)
            header("Описание", width: DashboardSessionTableLayout.descriptionWidth, alignment: .leading)
            header("Теги", alignment: .leading)
            header("Длительность", width: DashboardSessionTableLayout.durationWidth, alignment: .trailing)
            header("Сумма", width: DashboardSessionTableLayout.amountWidth, alignment: .trailing)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(AppColors.secondaryText)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.lg)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(AppColors.separator)
        }
    }

    private func header(_ title: String, width: CGFloat? = nil, alignment: Alignment) -> some View {
        Text(title)
            .frame(width: width, alignment: alignment)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
    }
}

private struct DashboardSessionRow: View {
    let session: WorkSession
    let currencyCode: String
    let isFirstRow: Bool

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Text(AppFormatters.relativeSessionStartText(session.startTime))
                .font(.system(size: 15, weight: .medium, design: .default).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: DashboardSessionTableLayout.timeWidth, alignment: .leading)

            HStack(spacing: AppSpacing.sm) {
                ProjectDot(colorHex: session.project?.colorHex ?? "#4C8BF5", size: 11)

                Text(session.project?.name ?? "Без проекта")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.primaryText)
                    .lineLimit(1)
            }
            .frame(width: DashboardSessionTableLayout.projectWidth, alignment: .leading)

            Text(session.note?.isEmpty == false ? session.note ?? "" : "Без описания")
                .font(.system(size: 15, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(AppColors.secondaryText)
                .frame(width: DashboardSessionTableLayout.descriptionWidth, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    if session.tags.isEmpty {
                        Text("—")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                    } else {
                        ForEach(session.tags, id: \.self) { tag in
                            TagChip(title: tag, color: AppColors.blue.opacity(0.9))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(AppFormatters.durationText(from: session.durationSeconds))
                .font(.system(size: 15, weight: .medium, design: .default).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: DashboardSessionTableLayout.durationWidth, alignment: .trailing)

            Text(
                AppFormatters.currencyText(
                    SessionCalculator().sessionIncome(session),
                    currencyCode: currencyCode
                )
            )
            .font(.system(size: 15, weight: .medium, design: .default).monospacedDigit())
            .foregroundStyle(AppColors.primaryText)
            .frame(width: DashboardSessionTableLayout.amountWidth, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, isFirstRow ? AppSpacing.lg : 14)
        .padding(.bottom, 14)
    }
}
