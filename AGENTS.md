# AGENTS.md

This file is the project-level instruction guide for Codex and other AI coding agents working on this repository.

Codex must read and follow this file before writing code, refactoring, fixing bugs, creating features, changing architecture, or modifying UI.

---

# Project: Native macOS Work Time Tracker

## Product summary

Build a native macOS application for Apple Silicon that tracks work time, projects, hourly rates, sessions, daily calendar summaries, period reports, income calculations, notes, tags, menu bar timer, local persistence, backups, and iCloud sync.

The application should feel like a high-quality Apple app designed for modern macOS, using SwiftUI, SwiftData, CloudKit, Swift Charts, SF Symbols, native controls, and a Liquid Glass-inspired design language.

The app is not a web dashboard. It must feel native, fast, calm, polished, and reliable.

## Product language

The application UI language for this repository is Russian.

All user-facing text, labels, buttons, empty states, errors, menus, sheets, helper copy, and newly added UI strings must be written in Russian unless the user explicitly requests another language.

Code identifiers may remain in English, but the shipped interface must stay Russian-first and consistent.

---

# Non-negotiable product rules

## Income calculation rule

Never calculate income as:

```text
total project time * current project hourly rate
```

Always calculate income per session:

```text
session income = session billable duration * session resolved hourly rate snapshot
period income = sum(session income for all matching sessions)
```

Rate priority when creating or updating a session:

```text
1. Session custom hourly rate
2. Project hourly rate
3. Global default hourly rate
```

Every completed session must store a `resolvedHourlyRateSnapshot` so that historical income does not unexpectedly change when the user later changes the global or project rate.

## Active timer rule

Only one active timer may exist at a time.

An active timer must be persisted immediately when started, not only when stopped. If the app crashes, quits, or restarts, the timer must survive and continue from its original `startTime`.

## Data safety rule

User time records are critical data. Never implement features in a way that can silently lose, overwrite, or corrupt work sessions.

Every destructive action must be explicit and recoverable where practical.

---

# Technology stack

Use the following stack unless the user explicitly asks to change it:

```text
Language: Swift
UI: SwiftUI
Architecture: MVVM + small service layer
Local persistence: SwiftData
Cloud sync: CloudKit with SwiftData-compatible models
Charts: Swift Charts
Platform: macOS, Apple Silicon first
Menu bar: MenuBarExtra
Notifications: UserNotifications
Design system: native macOS + Liquid Glass-inspired design kit
Testing: XCTest / Swift Testing where available
```

The design system is not optional polish. The UI kit must actively use a Liquid Glass-inspired visual language with reusable materials, layered translucency, soft borders, calm depth, and native macOS controls.

Do not introduce unnecessary third-party dependencies. Prefer Apple frameworks.

Third-party packages are allowed only if they solve a real problem that is painful to solve natively, are maintained, and do not compromise app reliability.

---

# Architecture

Use MVVM with a lightweight service/repository layer.

Recommended structure:

```text
WorkTimeTracker/
  App/
    WorkTimeTrackerApp.swift
    AppRouter.swift
    AppEnvironment.swift
  DesignSystem/
    AppTheme.swift
    AppSpacing.swift
    AppTypography.swift
    AppMaterials.swift
    AppButtons.swift
    AppCards.swift
    AppTables.swift
    AppFormatters.swift
  Models/
    Project.swift
    WorkSession.swift
    AppSettings.swift
    DayNote.swift
    Tag.swift
  Services/
    TimerService.swift
    SessionCalculator.swift
    ReportService.swift
    BackupService.swift
    ExportService.swift
    ImportService.swift
    NotificationService.swift
    CloudSyncStatusService.swift
  Repositories/
    ProjectRepository.swift
    SessionRepository.swift
    SettingsRepository.swift
  Features/
    Dashboard/
    Calendar/
    Reports/
    Projects/
    Sessions/
    Settings/
    MenuBarTimer/
  Shared/
    Components/
    Extensions/
    Utilities/
  Tests/
```

## Dependency direction

Features may depend on:

```text
Models
Services
Repositories
DesignSystem
Shared
```

Services and repositories must not depend on feature views.

DesignSystem must not depend on features.

Models must not depend on UI.

## Feature module pattern

Each feature should follow this structure when it grows beyond one small screen:

```text
Features/FeatureName/
  FeatureNameView.swift
  FeatureNameViewModel.swift
  Components/
  Models/
  Helpers/
```

For example:

```text
Features/Reports/
  ReportsView.swift
  ReportsViewModel.swift
  ReportPeriodPicker.swift
  ProjectReportTable.swift
  ReportSummaryCards.swift
  ReportCharts.swift
```

Keep feature-specific UI components inside the feature folder. Move components to `Shared/Components` only after they are reused by at least two features.

---

# Senior code standards

## General rules

Write code that is:

```text
Readable
Predictable
Composable
Testable
Performant
Native
Safe with user data
Easy to delete or refactor
```

Prefer boring, clear code over clever abstractions.

Do not over-engineer early, but do not create messy one-off code that will block future features.

## Swift style

Use:

```swift
struct` for value types
final class` for reference types that should not be subclassed
private` by default
let` by default
explicit access control for public/internal APIs when useful
async/await where appropriate
MainActor for UI-facing view models
```

Avoid:

```text
Massive views
Massive view models
Global mutable state
Force unwraps
Stringly typed business logic
Hidden side effects in computed properties
Business logic inside SwiftUI views
Duplicated date/rate/duration calculations
```

## View size rule

A SwiftUI view should usually stay under 150-250 lines.

If a view becomes large, split it into smaller components by responsibility:

```text
Header
SummaryCards
Toolbar
Table
EmptyState
DetailPanel
```

## ViewModel rule

ViewModels should coordinate state and user actions. They should not contain heavy calculation logic that belongs in services.

Good:

```swift
@MainActor
final class ReportsViewModel: ObservableObject {
    private let reportService: ReportService
    @Published var selectedPeriod: ReportPeriod
    @Published private(set) var report: PeriodReport?
}
```

Bad:

```swift
// 500-line ViewModel with date filtering, income calculation, CSV export,
// chart formatting, notification scheduling, and UI state all mixed together.
```

## Business logic rule

Put reusable business logic in services:

```text
SessionCalculator
ReportService
TimerService
ExportService
BackupService
```

All income, duration, rounding, date grouping, and report aggregation must be centralized and tested.

---

# Data models

## Project

Represents a client/project/work stream.

Recommended fields:

```swift
@Model
final class Project {
    var id: UUID
    var name: String
    var colorHex: String
    var iconName: String?
    var hourlyRate: Decimal?
    var isArchived: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}
```

## WorkSession

Represents one tracked work interval.

Recommended fields:

```swift
@Model
final class WorkSession {
    var id: UUID
    var project: Project?
    var startTime: Date
    var endTime: Date?
    var durationSeconds: TimeInterval
    var note: String?
    var tags: [String]
    var customHourlyRate: Decimal?
    var resolvedHourlyRateSnapshot: Decimal
    var createdAt: Date
    var updatedAt: Date
}
```

Rules:

- `endTime == nil` means active session.
- `durationSeconds` should be updated when a session is stopped or edited.
- For active timers, displayed duration should be calculated from `startTime` to now.
- `resolvedHourlyRateSnapshot` must be saved at session creation/completion and updated intentionally only when the user changes the session rate.

## AppSettings

Recommended fields:

```swift
@Model
final class AppSettings {
    var defaultHourlyRate: Decimal
    var currencyCode: String
    var roundingMode: String
    var roundingMinutes: Int
    var longTimerReminderMinutes: Int
    var iCloudSyncEnabled: Bool
    var autoBackupEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
}
```

## DayNote

Recommended fields:

```swift
@Model
final class DayNote {
    var id: UUID
    var date: Date
    var note: String
    var createdAt: Date
    var updatedAt: Date
}
```

---

# Core services

## SessionCalculator

Responsible for:

```text
Duration calculation
Billable duration calculation
Rounding
Rate resolution
Session income
Project income from sessions
Period income from sessions
Formatting helper data for reports
```

Must expose pure functions where possible.

Example API:

```swift
struct SessionCalculator {
    func resolvedRate(
        sessionCustomRate: Decimal?,
        projectRate: Decimal?,
        defaultRate: Decimal
    ) -> Decimal

    func durationSeconds(start: Date, end: Date) -> TimeInterval

    func billableDurationSeconds(
        rawDurationSeconds: TimeInterval,
        roundingMode: RoundingMode,
        roundingMinutes: Int
    ) -> TimeInterval

    func income(
        durationSeconds: TimeInterval,
        hourlyRate: Decimal
    ) -> Decimal
}
```

## TimerService

Responsible for:

```text
Starting a timer
Stopping a timer
Pausing/resuming if implemented
Restoring active timer after app launch
Guaranteeing only one active session
Updating menu bar state
Triggering long-running timer reminders
```

TimerService must not be tightly coupled to a specific screen.

## ReportService

Responsible for:

```text
Filtering sessions by period
Grouping by day
Grouping by project
Grouping by tag
Calculating totals
Building expandable report rows
Preparing chart data
```

Reports must always be calculated from sessions.

## BackupService

Responsible for:

```text
Creating JSON backups
Restoring from JSON
Scheduling automatic backups
Validating imported data
Avoiding duplicate imports
```

## ExportService

Responsible for:

```text
CSV export
JSON export
Optional future PDF export
```

---

# Features

## Dashboard

Must show:

```text
Active timer
Project selector
Session note
Tags
Optional custom session rate
Today worked time
Today income
Session count today
Most active project today
Recent sessions table
```

Dashboard should be optimized for quick daily use.

## Calendar

Calendar must show daily summaries.

For selected day, show a table grouped by projects, not just plain text.

Daily summary should include:

```text
Total time
Total income
Session count
Project count
Day note
```

Daily project table:

```text
Project
Time
Sessions
Income
```

Each project row must be expandable.

Expanded rows show sessions:

```text
Start
End
Description
Tags
Rate
Duration
Income
```

Important: daily income is the sum of session incomes for that date.

## Reports

Reports must support:

```text
Today
Yesterday
This week
Last week
This month
Last month
Custom range
Project filter
Tag filter
```

Report summary:

```text
Total time
Total income
Work days count
Session count
Average time per work day
Average income per work day
Most profitable project
Longest project
```

Project report table:

```text
Project
Time
Session count
Average informational rate
Income
```

Project rows must be expandable to show session-level details.

Charts:

```text
Income by day
Time by day
Time by project
Income by project
```

Use Swift Charts.

## Projects

Must support:

```text
Create project
Edit project
Archive project
Set project color
Set project icon
Set optional project hourly rate
View project sessions
View total project stats
```

Archived projects should not appear in quick-start lists by default, but their historical sessions must remain in reports.

## Sessions

Must support:

```text
Create manual session
Edit session
Delete session
Duplicate session
Change project
Change start/end time
Change note
Change tags
Change custom session rate
```

Editing a session must recalculate duration and income snapshot intentionally.

## Settings

Must support:

```text
Default hourly rate
Currency
Time format
First day of week
Timer reminder threshold
Rounding mode
Rounding minutes
iCloud sync status
Export JSON
Import JSON
Export CSV
Create backup
Theme mode
Accent color
Liquid Glass mode if applicable
```

## Menu Bar Timer

Use `MenuBarExtra`.

When timer is active, show:

```text
Elapsed time
Project name
Current estimated income
Pause/Resume if implemented
Stop
Open app
```

When no timer is active, show:

```text
Start timer
Recent projects
Open app
```

Menu bar timer must read from the same TimerService as the main app.

---

# Design system

## Design principles

The app should look like a native Apple productivity app.

Keywords:

```text
Calm
Precise
Glass-like
Minimal
Premium
Readable
Fast
Native
```

Inspired by:

```text
Apple Calendar
Apple Reminders
Apple Notes
Apple Shortcuts
Timing-style time tracking
Modern macOS Tahoe Liquid Glass
```

## Layout

Use:

```text
NavigationSplitView
Sidebar navigation
Cards for high-level stats
Tables for detailed records
Inspector/detail panels for editing
Sheets for create/edit flows
Popovers for quick actions
```

## Spacing

Create design tokens:

```swift
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

Do not hardcode random spacing everywhere.

## Typography

Use system fonts.

Recommended hierarchy:

```text
Large title: screen title
Title 2/3: section headers
Headline: card numbers and table section names
Body: main content
Callout/Caption: secondary metadata
Monospaced digits: timers, durations, money values
```

Timer values should use monospaced digits.

## Colors

Use semantic colors first:

```text
primary
secondary
background
secondaryBackground
accentColor
separator
```

Project colors may be custom, but must work in both light and dark mode.

Avoid hardcoded colors unless they are part of the design system.

## Materials

Use native macOS materials where possible.

Create reusable card/background components instead of repeating modifiers.

Example:

```swift
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
```

## Buttons

Create reusable button styles:

```text
Primary action
Secondary action
Destructive action
Timer start
Timer stop
Small toolbar button
```

Timer start/stop buttons must be visually obvious and easy to click.

## Tables

Tables should be clean and dense enough for productivity use.

Rules:

```text
Right-align durations and money
Use monospaced digits for numbers
Show empty states
Support sorting where useful
Support row expansion for reports and calendar
Avoid horizontal clutter
```

## Empty states

Every major screen needs a useful empty state.

Examples:

```text
No projects yet — Create your first project
No sessions today — Start a timer
No report data — Change the selected period
```

---

# Reusable code rules

## When to extract reusable components

Extract a component when:

```text
It appears in 2+ places
It has clear responsibility
It improves readability
It hides repeated styling
It is stable enough to name well
```

Do not extract too early just to look architectural.

## Good reusable components

Examples:

```text
GlassCard
SummaryMetricCard
MoneyText
DurationText
ProjectBadge
TagPill
DateRangePicker
EmptyStateView
EditableSessionSheet
ConfirmDeleteDialog
ExpandableProjectReportTable
```

## Formatting

Centralize formatting in `AppFormatters` or dedicated formatters:

```text
Currency formatting
Duration formatting
Date formatting
Time formatting
Percentage formatting
```

Do not format money/dates manually inside views.

---

# Performance rules

## SwiftUI performance

Avoid unnecessary recomputation in `body`.

Do not filter, group, and aggregate large session arrays directly inside SwiftUI views.

Do this in view models or services:

```swift
let report = reportService.buildReport(sessions: sessions, period: period)
```

Not this:

```swift
var body: some View {
    let grouped = sessions.filter(...).reduce(...)
    // Bad: heavy logic in body
}
```

## Data loading

Use targeted queries where possible.

For reports, fetch only sessions in the selected period when practical.

Do not load and aggregate years of sessions for every small UI update.

## Timer updates

Timer UI may update every second, but do not save to disk every second.

Persist on meaningful events:

```text
Start
Stop
Pause
Resume
Edit
App lifecycle transitions if needed
```

For active timer display, calculate elapsed time from `startTime` and current time.

## Charts

Precompute chart data in services or view models.

Do not do expensive grouping directly inside chart views.

---

# Testing rules

Prioritize tests for business logic.

Must test:

```text
Rate priority
Session income
Period income
Project grouping
Day grouping
Rounding
Active session restoration logic
Changing project rate does not break historical income snapshots
Manual session edit recalculates duration correctly
```

Example test cases:

```text
Session custom rate overrides project and global rate
Project rate overrides global rate
Global rate is used when no other rate exists
Period report sums individual session income
Changing project hourly rate does not change old session income
```

UI tests are useful but secondary.

---

# Error handling

Never silently fail on data operations.

User-facing errors should be calm and actionable.

Examples:

```text
Could not save session. Please try again.
Could not import backup. The file format is invalid.
Only one timer can run at a time.
```

Use typed errors in services where useful.

Avoid `try?` unless failure is truly harmless.

---

# iCloud and backup rules

Local data is primary. iCloud sync is additional.

The app must remain usable offline.

Implement:

```text
Local SwiftData persistence
CloudKit-ready model configuration
Manual JSON export
Manual JSON import
CSV export
Automatic backup option
```

Before implementing destructive import behavior, create a safe strategy:

```text
Validate file
Preview import count
Avoid duplicates by UUID
Do not delete existing data unless user explicitly chooses replace mode
```

---

# UX rules

## Timer UX

Starting a timer should be fast.

Ideal flow:

```text
Select project
Optional note
Optional tags
Optional custom rate
Start
```

Stopping should create or finalize a session immediately.

If user closes app with active timer, restore it next launch.

## Editing UX

Session editing should be possible from:

```text
Dashboard recent sessions
Calendar expanded rows
Reports expanded rows
Sessions screen
Project details
```

Prefer reusing one `EditableSessionSheet`.

## Confirmation UX

Require confirmation for:

```text
Deleting sessions
Deleting projects with sessions
Replacing data from import
Stopping very long timers if there may be accidental tracking
```

Do not over-confirm harmless actions.

---

# Accessibility

Use native controls and labels.

Requirements:

```text
VoiceOver labels for timer buttons
Sufficient contrast in light and dark mode
Do not rely only on color for project identity
Keyboard navigation for main actions
Large clickable targets for timer controls
```

---

# Localization readiness

Even if the first version is Russian-only or English-only, avoid hardcoding formatting assumptions.

Use:

```text
Locale-aware currency formatting
Locale-aware dates
Calendar-aware week starts
```

User-visible strings may later be moved to localization files.

---

# Coding workflow for Codex

When implementing a feature:

1. Read existing models, services, and feature folder.
2. Identify whether logic already exists before creating new logic.
3. Add or update models only when necessary.
4. Put business logic into services.
5. Keep views small and composable.
6. Reuse design-system components.
7. Add tests for calculations or non-trivial logic.
8. Run build/tests if available.
9. Summarize what changed and mention any limitations.

When refactoring:

1. Preserve behavior unless explicitly asked to change it.
2. Avoid large unrelated rewrites.
3. Keep public APIs stable where possible.
4. Improve naming and separation of concerns.
5. Add tests around previously untested business logic.

When fixing bugs:

1. Reproduce or reason through the bug.
2. Find root cause.
3. Make minimal safe fix.
4. Add regression test where practical.
5. Do not mask the bug with UI-only workarounds.

---

# Naming conventions

Use clear domain names:

```text
Project
WorkSession
DayNote
ReportPeriod
ProjectReportRow
SessionReportRow
SessionCalculator
TimerService
ReportService
```

Avoid vague names:

```text
Manager
Helper
Utils
DataModel
Item
Thing
Info
```

A type named `Manager` is allowed only if no better domain name exists.

---

# Commit/change discipline

Keep changes focused.

Do not mix unrelated tasks, for example:

```text
Do not redesign Dashboard while fixing CSV export.
Do not change persistence model while adding button styling.
Do not refactor all files while implementing one report filter.
```

If a larger refactor is necessary, explain why.

---

# Security and privacy

The app stores sensitive work and income data.

Rules:

```text
Do not send user data to external services
Do not add analytics by default
Do not log personal notes, income, project names, or session details
Do not expose CloudKit identifiers in UI
Keep backups local unless user explicitly exports/shares them
```

---

# MVP priority order

Build in this order:

1. Data models and local persistence.
2. Projects CRUD.
3. Timer start/stop with one active session.
4. Session creation/editing.
5. Correct income calculation with rate snapshots.
6. Dashboard.
7. Calendar daily table with expandable projects.
8. Reports with period picker and expandable project rows.
9. Settings.
10. Export/import JSON and CSV.
11. MenuBarExtra timer.
12. Long timer reminders.
13. iCloud sync.
14. Liquid Glass polish and advanced charts.

Do not start with visual polish before the core tracking and calculation logic is reliable.

---

# Definition of done

A feature is done only when:

```text
It works correctly
It follows architecture rules
It uses reusable design components where appropriate
It does not duplicate business logic
It handles empty and error states
It does not break existing data
It has tests for non-trivial calculations
It feels native on macOS
```

---

# Final instruction for Codex

When in doubt, optimize for:

```text
Data safety
Correct income calculation
Native macOS experience
Readable senior-level Swift code
Reusable feature architecture
Simple, testable business logic
```
