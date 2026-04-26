import Foundation
import Observation

@MainActor
@Observable
final class CalendarViewModel {
    private let sessionRepository: SessionRepository
    private let settingsRepository: SettingsRepository
    private let dayNoteRepository: DayNoteRepository
    private let reportService: ReportService
    private let appEnvironment: AppEnvironment
    private var calendar: Calendar
    private var allSessions: [WorkSession] = []
    private var dayNoteSaveTask: Task<Void, Never>?

    private(set) var settings: AppSettings?
    private(set) var selectedDaySummary: DaySummaryReport?
    private(set) var monthDays: [CalendarDayItem] = []
    private(set) var noteStatus: DayNoteStatus = .saved(nil)
    var selectedDate = Date.now
    var displayedMonth = Date.now
    var dayNoteText = ""
    var expandedProjectIDs = Set<String>()
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.sessionRepository = appEnvironment.sessionRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.dayNoteRepository = appEnvironment.dayNoteRepository
        self.reportService = appEnvironment.reportService
        self.appEnvironment = appEnvironment

        var configuredCalendar = Calendar(identifier: .gregorian)
        configuredCalendar.locale = Locale(identifier: "ru_RU")
        configuredCalendar.firstWeekday = 2
        self.calendar = configuredCalendar
        self.displayedMonth = configuredCalendar.date(from: configuredCalendar.dateComponents([.year, .month], from: .now)) ?? .now
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }

    var monthTitle: String {
        AppFormatters.monthYearText(displayedMonth)
    }

    var selectedDateTitle: String {
        AppFormatters.dayMonthText(selectedDate)
    }

    var noteStatusText: String {
        switch noteStatus {
        case .saved(let date):
            let savedAt = date ?? .now
            return "✓ Сохранено в \(AppFormatters.statusTimeText(savedAt))"
        case .saving:
            return "Сохраняем..."
        case .changed:
            return "Есть несохраненные изменения"
        case .error:
            return "Не удалось сохранить"
        }
    }

    func load() {
        appEnvironment.bootstrap()
        reload()
    }

    func reload() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            calendar.firstWeekday = settings?.firstDayOfWeek ?? 2
            allSessions = try sessionRepository.fetchAll()
            errorMessage = appEnvironment.bootstrapErrorMessage
            rebuildSelectedDay()
            rebuildMonthDays()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
        displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)) ?? displayedMonth
        expandedProjectIDs.removeAll()
        rebuildSelectedDay()
        rebuildMonthDays()
    }

    func showPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        rebuildMonthDays()
    }

    func showNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        rebuildMonthDays()
    }

    func dayNoteDidChange() {
        noteStatus = .changed
        dayNoteSaveTask?.cancel()
        dayNoteSaveTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(for: .milliseconds(700))
            guard Task.isCancelled == false else { return }
            self.persistDayNote()
        }
    }

    func persistDayNote() {
        noteStatus = .saving

        do {
            try dayNoteRepository.save(note: dayNoteText, for: selectedDate)
            let refreshedNote = try dayNoteRepository.fetch(for: selectedDate)
            noteStatus = .saved(refreshedNote?.updatedAt ?? .now)
            appEnvironment.notifyDataChanged()
            rebuildSelectedDay(dayNoteOverride: refreshedNote)
        } catch {
            noteStatus = .error
            errorMessage = error.localizedDescription
        }
    }

    private func rebuildSelectedDay(dayNoteOverride: DayNote? = nil) {
        do {
            let dayNote = try dayNoteRepository.fetch(for: selectedDate)
            let resolvedNote = dayNoteOverride ?? dayNote
            selectedDaySummary = reportService.buildDaySummary(
                sessions: allSessions,
                selectedDate: selectedDate,
                dayNote: resolvedNote,
                calendar: calendar
            )
            dayNoteText = resolvedNote?.note ?? ""
            noteStatus = .saved(resolvedNote?.updatedAt)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rebuildMonthDays() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            monthDays = []
            return
        }

        let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start ?? monthInterval.start
        let lastMonthMoment = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthInterval.start) ?? monthInterval.start
        let lastWeekEnd = calendar.dateInterval(of: .weekOfYear, for: lastMonthMoment)?.end ?? monthInterval.end
        let totalDays = calendar.dateComponents([.day], from: firstWeekStart, to: lastWeekEnd).day ?? 0

        monthDays = (0..<totalDays).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: firstWeekStart) else {
                return nil
            }

            let summary = reportService.buildDaySummary(
                sessions: allSessions,
                selectedDate: day,
                dayNote: nil,
                calendar: calendar
            )

            return CalendarDayItem(
                date: day,
                dayNumber: calendar.component(.day, from: day),
                isWithinDisplayedMonth: calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month),
                isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                totalDurationSeconds: summary.totalDurationSeconds,
                totalIncome: summary.totalIncome,
                projectColorHexes: summary.projectRows.compactMap { row in
                    allSessions.first(where: { $0.project?.id == row.projectID })?.project?.colorHex
                }
            )
        }
    }
}

struct CalendarDayItem: Identifiable {
    let date: Date
    let dayNumber: Int
    let isWithinDisplayedMonth: Bool
    let isSelected: Bool
    let totalDurationSeconds: TimeInterval
    let totalIncome: Decimal
    let projectColorHexes: [String]

    var id: Date { date }
}

enum DayNoteStatus {
    case saved(Date?)
    case saving
    case changed
    case error
}
