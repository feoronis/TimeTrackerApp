import SwiftUI

struct CalendarSummaryCards: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.md),
                GridItem(.flexible(), spacing: AppSpacing.md)
            ],
            spacing: AppSpacing.md
        ) {
            CalendarMetricCard(
                title: "Проработано",
                value: AppFormatters.compactDurationText(from: viewModel.selectedDaySummary?.totalDurationSeconds ?? 0)
            )

            CalendarMetricCard(
                title: "Доход",
                value: AppFormatters.currencyText(
                    viewModel.selectedDaySummary?.totalIncome ?? .zero,
                    currencyCode: viewModel.currencyCode
                )
            )

            CalendarMetricCard(
                title: "Сессий",
                value: "\(viewModel.selectedDaySummary?.sessionCount ?? 0)"
            )

            CalendarMetricCard(
                title: "Проектов",
                value: "\(viewModel.selectedDaySummary?.projectCount ?? 0)"
            )
        }
    }
}

private struct CalendarMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppColors.glassHighlight.opacity(0.14), lineWidth: 1)
        }
    }
}

struct CalendarDetailsPanel: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                HStack {
                    Text(viewModel.selectedDateTitle)
                        .font(.title2.weight(.semibold))

                    Spacer()

                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                CalendarSummaryCards(viewModel: viewModel)
                CalendarProjectsSection(viewModel: viewModel)
                CalendarDayNoteSection(viewModel: viewModel)
            }
        }
    }
}

private struct CalendarDayNoteSection: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Заметка дня")
                .font(.headline)

            TextEditor(text: $viewModel.dayNoteText)
                .font(.body)
                .frame(minHeight: 140)
                .padding(AppSpacing.sm)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppColors.glassHighlight.opacity(0.2), lineWidth: 1)
                }
                .onChange(of: viewModel.dayNoteText, initial: false) {
                    viewModel.dayNoteDidChange()
                }

            Text(viewModel.noteStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CalendarProjectsSection: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("По проектам")
                .font(.headline)

            if let summary = viewModel.selectedDaySummary, summary.projectRows.isEmpty == false {
                CalendarProjectHeaderRow()

                VStack(spacing: 0) {
                    ForEach(summary.projectRows) { row in
                        CalendarProjectRow(
                            row: row,
                            currencyCode: viewModel.currencyCode,
                            isExpanded: viewModel.expandedProjectIDs.contains(row.id),
                            toggleExpansion: {
                                if viewModel.expandedProjectIDs.contains(row.id) {
                                    viewModel.expandedProjectIDs.remove(row.id)
                                } else {
                                    viewModel.expandedProjectIDs.insert(row.id)
                                }
                            }
                        )

                        if row.id != summary.projectRows.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                EmptyStateView(
                    title: "Нет данных за день",
                    message: "Выберите другой день в календаре или добавьте сессию.",
                    systemImage: "calendar.badge.exclamationmark"
                )
                .frame(minHeight: 180)
            }
        }
    }
}

private struct CalendarProjectHeaderRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("Проект").frame(maxWidth: .infinity, alignment: .leading)
            Text("Время").frame(width: 78, alignment: .trailing)
            Text("Сессий").frame(width: 64, alignment: .trailing)
            Text("Сумма").frame(width: 92, alignment: .trailing)
            Color.clear.frame(width: 24)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, AppSpacing.md)
    }
}

private struct CalendarProjectRow: View {
    let row: ProjectReportRow
    let currencyCode: String
    let isExpanded: Bool
    let toggleExpansion: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggleExpansion) {
                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.sm) {
                        ProjectDot(colorHex: projectColorHex, size: 9)
                        Text(row.projectName)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(AppFormatters.compactDurationText(from: row.totalDurationSeconds))
                        .font(.callout.monospacedDigit())
                        .frame(width: 78, alignment: .trailing)

                    Text("\(row.sessionCount)")
                        .frame(width: 64, alignment: .trailing)

                    Text(AppFormatters.currencyText(row.income, currencyCode: currencyCode))
                        .font(.callout.monospacedDigit())
                        .frame(width: 92, alignment: .trailing)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    CalendarSessionHeaderRow()

                    ForEach(row.sessions) { session in
                        CalendarSessionRow(session: session, currencyCode: currencyCode)

                        if session.id != row.sessions.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
        }
    }

    private var projectColorHex: String {
        "#4C8BF5"
    }
}

private struct CalendarSessionHeaderRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text("Старт").frame(width: 46, alignment: .leading)
            Text("Конец").frame(width: 46, alignment: .leading)
            Text("Описание").frame(maxWidth: .infinity, alignment: .leading)
            Text("Теги").frame(width: 110, alignment: .leading)
            Text("Ставка").frame(width: 86, alignment: .trailing)
            Text("Время").frame(width: 72, alignment: .trailing)
            Text("Сумма").frame(width: 86, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.top, AppSpacing.sm)
        .padding(.bottom, AppSpacing.xs)
    }
}

private struct CalendarSessionRow: View {
    let session: SessionReportRow
    let currencyCode: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(AppFormatters.statusTimeText(session.startTime))
                .frame(width: 46, alignment: .leading)

            Text(session.endTime.map(AppFormatters.statusTimeText) ?? "—")
                .frame(width: 46, alignment: .leading)

            Text(session.note?.isEmpty == false ? session.note ?? "" : "Без описания")
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

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
            .frame(width: 110, alignment: .leading)

            Text(AppFormatters.currencyText(session.hourlyRate, currencyCode: currencyCode) + "/ч")
                .frame(width: 86, alignment: .trailing)

            Text(AppFormatters.durationText(from: session.durationSeconds))
                .font(.caption.monospacedDigit())
                .frame(width: 72, alignment: .trailing)

            Text(AppFormatters.currencyText(session.income, currencyCode: currencyCode))
                .font(.caption.monospacedDigit())
                .frame(width: 86, alignment: .trailing)
        }
        .font(.caption)
        .padding(.vertical, AppSpacing.xs)
    }
}
