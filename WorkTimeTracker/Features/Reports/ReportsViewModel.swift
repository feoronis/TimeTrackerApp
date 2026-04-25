import Foundation
import Observation

@MainActor
@Observable
final class ReportsViewModel {
    private let reportService: ReportService
    private let sessionRepository: SessionRepository
    private let projectRepository: ProjectRepository
    private let settingsRepository: SettingsRepository
    private let appEnvironment: AppEnvironment
    private(set) var settings: AppSettings?
    private(set) var projects: [Project] = []
    private(set) var report: PeriodReport?
    var filter: ReportFilter
    var expandedProjectIDs = Set<String>()
    var errorMessage: String?

    init(appEnvironment: AppEnvironment) {
        self.reportService = appEnvironment.reportService
        self.sessionRepository = appEnvironment.sessionRepository
        self.projectRepository = appEnvironment.projectRepository
        self.settingsRepository = appEnvironment.settingsRepository
        self.appEnvironment = appEnvironment
        self.filter = ReportFilter(
            period: .thisWeek,
            customStartDate: .now,
            customEndDate: .now
        )
    }

    func load() {
        appEnvironment.bootstrap()
        reload()
    }

    func reload() {
        do {
            settings = try settingsRepository.fetchOrCreateSettings()
            projects = try projectRepository.fetchAll()
            let sessions = try sessionRepository.fetchAll()
            report = reportService.buildPeriodReport(
                sessions: sessions,
                filter: filter
            )
            errorMessage = appEnvironment.bootstrapErrorMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyFilters() {
        expandedProjectIDs.removeAll()
        reload()
    }

    var currencyCode: String {
        settings?.currencyCode ?? "RUB"
    }
}
