import SwiftUI

struct ExpandableProjectReportList: View {
    let title: String
    let projectRows: [ProjectReportRow]
    let currencyCode: String
    @Binding var expandedProjectIDs: Set<String>

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(title)
                    .font(.headline)

                if projectRows.isEmpty {
                    EmptyStateView(
                        title: "Нет данных",
                        message: "Попробуйте изменить дату или фильтры.",
                        systemImage: "tray"
                    )
                    .frame(minHeight: 200)
                } else {
                    ForEach(projectRows) { row in
                        DisclosureGroup(
                            isExpanded: binding(for: row.id),
                            content: {
                                VStack(alignment: .leading, spacing: AppSpacing.md) {
                                    ForEach(row.sessions) { session in
                                        SessionBreakdownRow(
                                            session: session,
                                            currencyCode: currencyCode
                                        )

                                        if session.id != row.sessions.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(.top, AppSpacing.sm)
                            },
                            label: {
                                ProjectBreakdownHeader(
                                    row: row,
                                    currencyCode: currencyCode
                                )
                            }
                        )

                        if row.id != projectRows.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func binding(for projectID: String) -> Binding<Bool> {
        Binding(
            get: { expandedProjectIDs.contains(projectID) },
            set: { isExpanded in
                if isExpanded {
                    expandedProjectIDs.insert(projectID)
                } else {
                    expandedProjectIDs.remove(projectID)
                }
            }
        )
    }
}

private struct ProjectBreakdownHeader: View {
    let row: ProjectReportRow
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(row.projectName)
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                Text("\(row.sessionCount) сессий")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)

                Text("Средняя ставка: \(AppFormatters.currencyText(row.averageInformationalRate, currencyCode: currencyCode))")
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(AppFormatters.durationText(from: row.totalDurationSeconds))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)

                Text(AppFormatters.currencyText(row.income, currencyCode: currencyCode))
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}

private struct SessionBreakdownRow: View {
    let session: SessionReportRow
    let currencyCode: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(AppFormatters.timeText(session.startTime))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)

                    Text("-")
                        .foregroundStyle(AppColors.secondaryText)

                    Text(session.endTime.map(AppFormatters.timeText) ?? "Активна")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                }

                if let note = session.note, note.isEmpty == false {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(AppColors.primaryText)
                }

                if session.tags.isEmpty == false {
                    Text(session.tags.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(AppFormatters.durationText(from: session.durationSeconds))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppColors.primaryText)

                Text(AppFormatters.currencyText(session.income, currencyCode: currencyCode))
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)

                Text(AppFormatters.currencyText(session.hourlyRate, currencyCode: currencyCode))
                    .font(.caption2)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }
}
