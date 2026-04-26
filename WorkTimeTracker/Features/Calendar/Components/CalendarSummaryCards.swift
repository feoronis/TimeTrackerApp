import SwiftUI

struct CalendarSummaryCards: View {
    @Bindable var viewModel: CalendarViewModel
    let isCompact: Bool

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
                value: AppFormatters.compactDurationText(from: viewModel.selectedDaySummary?.totalDurationSeconds ?? 0),
                systemImage: "clock",
                iconBackground: AppColors.blue.opacity(0.14),
                iconColor: AppColors.blue,
                isCompact: isCompact
            )

            CalendarMetricCard(
                title: "Доход",
                value: AppFormatters.currencyText(
                    viewModel.selectedDaySummary?.totalIncome ?? .zero,
                    currencyCode: viewModel.currencyCode
                ),
                systemImage: "rublesign.circle",
                iconBackground: AppColors.purple.opacity(0.14),
                iconColor: AppColors.purple,
                isCompact: isCompact
            )

            CalendarMetricCard(
                title: "Сессий",
                value: "\(viewModel.selectedDaySummary?.sessionCount ?? 0)",
                systemImage: "chart.bar",
                iconBackground: AppColors.orange.opacity(0.18),
                iconColor: AppColors.orange,
                isCompact: isCompact
            )

            CalendarMetricCard(
                title: "Проектов",
                value: "\(viewModel.selectedDaySummary?.projectCount ?? 0)",
                systemImage: "folder",
                iconBackground: AppColors.pink.opacity(0.14),
                iconColor: AppColors.pink,
                isCompact: isCompact
            )
        }
    }
}

private struct CalendarMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let iconBackground: Color
    let iconColor: Color
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: isCompact ? 13 : 14, weight: .medium))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(value)
                .font(.system(size: isCompact ? 18 : 20, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.xs)

            HStack {
                Spacer(minLength: 0)

                Image(systemName: systemImage)
                    .font(.system(size: isCompact ? 18 : 21, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: isCompact ? 36 : 42, height: isCompact ? 36 : 42)
                    .background(iconBackground, in: Circle())
            }
        }
        .frame(maxWidth: .infinity, minHeight: isCompact ? 76 : 88, alignment: .leading)
        .padding(isCompact ? AppSpacing.md : AppSpacing.lg)
        .background(AppColors.cardSecondaryFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColors.tableBorder, lineWidth: 1)
        }
        .shadow(color: AppColors.subtleShadow.opacity(0.9), radius: 8, y: 4)
    }
}

struct CalendarDetailsPanel: View {
    @Bindable var viewModel: CalendarViewModel
    let isCompact: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                HStack {
                    Text(viewModel.selectedDateTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Spacer()
                }

                CalendarSummaryCards(viewModel: viewModel, isCompact: isCompact)
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
                .foregroundStyle(AppColors.primaryText)

            TextEditor(text: $viewModel.dayNoteText)
                .font(.body)
                .foregroundStyle(AppColors.primaryText)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 140)
                .padding(AppSpacing.sm)
                .background(AppColors.fieldFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.fieldBorder, lineWidth: 1)
                }
                .onChange(of: viewModel.dayNoteText, initial: false) {
                    viewModel.dayNoteDidChange()
                }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: noteStatusIconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)

                Text(viewModel.noteStatusText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    private var noteStatusIconName: String {
        switch viewModel.noteStatus {
        case .saved:
            return "checkmark.circle"
        case .saving:
            return "arrow.triangle.2.circlepath"
        case .changed:
            return "pencil.circle"
        case .error:
            return "exclamationmark.circle"
        }
    }
}

private struct CalendarProjectsSection: View {
    @Bindable var viewModel: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("По проектам")
                .font(.headline)
                .foregroundStyle(AppColors.primaryText)

            if let summary = viewModel.selectedDaySummary, summary.projectRows.isEmpty == false {
                CalendarProjectHeaderRow()

                VStack(spacing: 0) {
                    ForEach(summary.projectRows) { row in
                        CalendarProjectRow(
                            row: row,
                            currencyCode: viewModel.currencyCode,
                            isExpanded: viewModel.expandedProjectIDs.contains(row.id),
                            toggleExpansion: {
                                withAnimation(.snappy(duration: 0.34, extraBounce: 0.03)) {
                                    if viewModel.expandedProjectIDs.contains(row.id) {
                                        viewModel.expandedProjectIDs.remove(row.id)
                                    } else {
                                        viewModel.expandedProjectIDs.insert(row.id)
                                    }
                                }
                            }
                        )

                        if row.id != summary.projectRows.last?.id {
                            Divider()
                        }
                    }
                }
                .background(AppColors.tableFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColors.tableBorder, lineWidth: 1)
                }
                .animation(.snappy(duration: 0.34, extraBounce: 0.03), value: viewModel.expandedProjectIDs)
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
        .foregroundStyle(AppColors.secondaryText)
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
                        ProjectDot(colorHex: projectColorHex, size: 11)
                        Text(row.projectName)
                            .foregroundStyle(AppColors.primaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(AppFormatters.compactDurationText(from: row.totalDurationSeconds))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 78, alignment: .trailing)

                    Text("\(row.sessionCount)")
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 64, alignment: .trailing)

                    Text(AppFormatters.currencyText(row.income, currencyCode: currencyCode))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(AppColors.primaryText)
                        .frame(width: 92, alignment: .trailing)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(width: 24)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        CalendarSessionHeaderRow()

                        ForEach(row.sessions) { session in
                            CalendarSessionRow(session: session, currencyCode: currencyCode)

                            if session.id != row.sessions.last?.id {
                                Divider()
                            }
                        }
                    }
                    .frame(minWidth: 540, alignment: .leading)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.snappy(duration: 0.34, extraBounce: 0.03), value: isExpanded)
    }

    private var projectColorHex: String {
        row.projectColorHex ?? "#5B7CFA"
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
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(AppColors.secondaryText)
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
                .font(.system(size: 14, weight: .medium))
                .frame(width: 46, alignment: .leading)

            Text(session.endTime.map(AppFormatters.statusTimeText) ?? "—")
                .font(.system(size: 14, weight: .medium))
                .frame(width: 46, alignment: .leading)

            Text(session.note?.isEmpty == false ? session.note ?? "" : "Без описания")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    if session.tags.isEmpty {
                        Text("—")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.secondaryText)
                    } else {
                        ForEach(session.tags, id: \.self) { tag in
                            TagChip(title: tag, color: AppColors.blue.opacity(0.9))
                        }
                    }
                }
            }
            .frame(width: 110, alignment: .leading)

            Text(AppFormatters.currencyText(session.hourlyRate, currencyCode: currencyCode) + "/ч")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 86, alignment: .trailing)

            Text(AppFormatters.durationText(from: session.durationSeconds))
                .font(.system(size: 14, weight: .medium, design: .default).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 72, alignment: .trailing)

            Text(AppFormatters.currencyText(session.income, currencyCode: currencyCode))
                .font(.system(size: 14, weight: .medium, design: .default).monospacedDigit())
                .foregroundStyle(AppColors.primaryText)
                .frame(width: 86, alignment: .trailing)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
