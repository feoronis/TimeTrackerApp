import SwiftUI

struct RecentSessionsCard: View {
    let sessions: [WorkSession]
    let currencyCode: String
    let onShowAllSessions: (() -> Void)?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Последние сессии")
                    .font(.title3.weight(.semibold))

                if sessions.isEmpty {
                    EmptyStateView(
                        title: "Сессий пока нет",
                        message: "Запустите и завершите таймер, чтобы здесь появилась первая активность.",
                        systemImage: "clock.badge.questionmark"
                    )
                    .frame(minHeight: 220)
                } else {
                    DashboardSessionTableHeader()

                    VStack(spacing: 0) {
                        ForEach(sessions) { session in
                            DashboardSessionRow(session: session, currencyCode: currencyCode)

                            if session.id != sessions.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

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

private struct DashboardSessionTableHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            header("Время", width: 110, alignment: .leading)
            header("Проект", width: 250, alignment: .leading)
            header("Описание", width: 220, alignment: .leading)
            header("Теги", width: 220, alignment: .leading)
            header("Длительность", width: 120, alignment: .trailing)
            header("Сумма", width: 120, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, AppSpacing.lg)
    }

    private func header(_ title: String, width: CGFloat, alignment: Alignment) -> some View {
        Text(title)
            .frame(width: width, alignment: alignment)
    }
}

private struct DashboardSessionRow: View {
    let session: WorkSession
    let currencyCode: String

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Text(AppFormatters.relativeSessionStartText(session.startTime))
                .font(.callout.monospacedDigit())
                .frame(width: 110, alignment: .leading)

            HStack(spacing: AppSpacing.sm) {
                ProjectDot(colorHex: session.project?.colorHex ?? "#4C8BF5", size: 9)

                Text(session.project?.name ?? "Без проекта")
                    .lineLimit(1)
            }
            .frame(width: 250, alignment: .leading)

            Text(session.note?.isEmpty == false ? session.note ?? "" : "Без описания")
                .lineLimit(1)
                .foregroundStyle(.secondary)
                .frame(width: 220, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    if session.tags.isEmpty {
                        Text("—")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.tags, id: \.self) { tag in
                            TagChip(title: tag, color: AppColors.accent)
                        }
                    }
                }
            }
            .frame(width: 220, alignment: .leading)

            Text(AppFormatters.durationText(from: session.durationSeconds))
                .font(.callout.monospacedDigit())
                .frame(width: 120, alignment: .trailing)

            Text(
                AppFormatters.currencyText(
                    SessionCalculator().sessionIncome(session),
                    currencyCode: currencyCode
                )
            )
            .font(.callout.monospacedDigit())
            .frame(width: 120, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }
}
