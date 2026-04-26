# AGENTS.md

This file is the project-level instruction guide for Codex and other AI coding agents working on this repository.

Codex must read and follow this file before writing code, refactoring, fixing bugs, creating features, changing architecture, or modifying UI.

---

# Project: Native macOS Work Time Tracker

## Product summary

Build a native macOS application for Apple Silicon that tracks work time, projects, hourly rates, sessions, daily calendar summaries, period reports, income calculations, notes, tags, menu bar timer, local persistence, backups, and iCloud sync.

The application should feel like a high-quality Apple productivity app for modern macOS, using SwiftUI, SwiftData, CloudKit, Swift Charts, SF Symbols, native controls, and a strict Glass SaaS + Gradient design language with layered depth, soft translucency, and strong visual hierarchy.

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
Design system: native macOS + Glass SaaS gradient design kit
Testing: XCTest / Swift Testing where available
```

The design system is not optional polish. The UI kit must actively use the repository design language: glass surfaces, layered depth, soft gradients, neon-accent glow in dark mode, calm spacing, and native macOS controls interpreted through a premium SaaS-like composition.

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
Glass gradient mode if applicable
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

This repository uses a strict visual system. Codex must treat it as mandatory, not inspirational.

The target look is:

```text
Native macOS productivity app
+ Glass SaaS layering
+ Soft gradients
+ Neon-accent glow in dark mode
+ Premium calm depth instead of hard borders
```

Codex must think:

```text
I am not drawing flat blocks.
I am building visual hierarchy through light, air, layering, grouping, and depth.
```

If an existing screen is being created or refactored, Codex must prefer this design language over generic SwiftUI defaults.

## Global visual rules

Always do:

```text
Use layered surfaces instead of flat fills
Use gradients for primary emphasis
Use glow in dark mode for active and highlighted elements
Use soft separation through shadow, translucency, and contrast
Use generous spacing and clear grouping
Keep the interface calm, premium, and readable
```

Never do:

```text
Pure black backgrounds (#000000)
Harsh borders
Flat UI with plain gray blocks
Chaotic layouts
Overloaded containers mixing unrelated content
Multiple competing primary actions in one focus area
```

## Visual hierarchy formula

Default decision order:

```text
Depth (layers)
+ Spacing (air)
+ Glow (focus)
+ Grid (structure)
= final UI
```

If Codex is unsure, choose:

```text
More soft
More deep
More luminous in dark mode
More structured
```

## Design tokens

Create and reuse centralized tokens in the design system. Do not scatter magic values across views.

Required token families:

```text
AppSpacing
AppRadii
AppColors
AppGradients
AppShadows
AppMaterials
AppTypography
```

Recommended core values:

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

Recommended additional tokens:

```swift
enum AppRadii {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
}
```

Design color foundation:

```text
Dark background base: #020617
Dark background gradient end: #0F172A
Dark panel/card tint: rgba(30, 41, 59, 0.6)
Light background: #F8FAFC
Light panel: #FFFFFF
Primary accent: #5B7CFA
Secondary accent: #8F5CF6
Success: #22C55E
Warning: #F59E0B
Error: #EF4444
Dark primary text: #E2E8F0
Dark secondary text: #94A3B8
Dark muted text: #64748B
Border substitute: rgba(255,255,255,0.04-0.08)
```

Use these values through semantic wrappers in Swift, not as repeated inline literals.

## Layering system

Every screen should be composed through layers:

```text
Layer 0: background
Layer 1: primary surface
Layer 2: cards and grouped content
Layer 3: interactive or active states
```

Layer guidance:

```text
Layer 0 dark: deep blue-black gradient from #020617 to #0F172A
Layer 0 light: soft light background around #F8FAFC
Layer 1: glass-like main panel with blur, translucency, and calm contrast
Layer 2: cards with tinted fills, subtle highlight border, rounded corners, and depth shadow
Layer 3: hover, selected, focused, and active states using gradient or accent-tinted overlays
```

Primary surfaces should read as glass or softly frosted, not as opaque slabs.

## Layout and composition

Default app shell:

```text
[ Sidebar ] [ Main Content ]
```

Layout rules:

```text
Sidebar width: 220-260px
Main content horizontal padding: 24-32px
Comfortable content max width: about 1200-1400px where appropriate
Section gap: 24px
Inner block padding: 16-24px
Small element gaps: 8-12px
```

Every screen should generally follow this order:

```text
Header (title + key actions)
Filters / controls
KPI / summary row
Main content (table, calendar, chart, detail)
Secondary content (notes, inspector, supporting details)
```

Grouping rules:

```text
One container = one task
KPI blocks separate from tables
Tables separate from charts
Actions separate from dense data
Avoid long mixed-content slabs
Avoid more than two levels of visual nesting
```

If layout feels cramped, increase spacing before adding more borders or separators.

## Sidebar

The sidebar is a first-class visual anchor, not a default list.

Rules:

```text
Use a dark vertical gradient in dark mode, approximately #0B0F1F to #0F172A
Active item uses the primary gradient and visible glow
Hover uses a soft translucent highlight
Keep items aligned, calm, and evenly spaced
Do not make the sidebar visually flat
```

## Cards and surfaces

Cards must feel elevated through depth and translucency, not through thick outlines.

Card rules:

```text
Corner radius: 16-20px
Padding: 16-24px
Use tinted or glass-like backgrounds
Prefer soft shadow + subtle highlight edge over explicit stroke
Avoid nested card-inside-card-inside-card compositions
```

Recommended dark card treatment:

```text
Background: rgba(30, 41, 59, 0.6)
Highlight edge: rgba(255,255,255,0.06)
Shadow: deep outer shadow + subtle inner highlight
```

KPI cards should be uniform in width and height inside the same row.

## Hero timer and KPI blocks

The active timer hero is the brightest focal point on the dashboard.

Rules:

```text
Use the primary gradient or an accent-tinted gradient background
Use large monospaced digits
Make the timer visually dominate nearby KPI content
Use glow in dark mode
```

KPI row rules:

```text
Use 4 or 5 cards in a row when space allows
Keep equal heights
Typical height: about 100-120px
Value is the focal point
Label is secondary
Icon sits top-left or left-aligned
```

## Typography

Use system fonts, but with deliberate hierarchy and stronger numerical emphasis.

Recommended hierarchy:

```text
Large title: screen title
Title 2/3: section headers
Headline: KPI values and important subheaders
Body: main content
Callout/Caption: secondary metadata
Monospaced digits: timers, durations, money values, row metrics
```

Typography color guidance:

```text
Primary text dark: #E2E8F0
Primary text light: #1F2937
Secondary text: #94A3B8
Muted text: #64748B
```

Timer values, money, and key metrics should use monospaced digits and may use a subtle glow in dark mode.

## Colors and gradients

The primary brand emphasis must use this gradient:

```text
linear-gradient(135deg, #5B7CFA, #8F5CF6)
```

Use it for:

```text
Primary buttons
Active navigation states
Timer hero
Focused highlights
Selected key controls
Important chart accents
```

Project colors may be custom, but must still harmonize with the system in light and dark mode.

## Glow, shadows, and separation

Light and shadow are the main separation tool.

Rules:

```text
Do not rely on hard borders
Do not use heavy flat gray fills
Use glow for active or focused elements in dark mode
Use soft deep shadows for cards and hero blocks
Use subtle inner highlights where appropriate
```

Typical patterns:

```text
Card: deep outer shadow + faint inner highlight
Active element: accent outline glow + soft accent bloom
Primary button: colored shadow based on the primary gradient
```

## Buttons

Create reusable button styles and apply them consistently.

Required button families:

```text
Primary action
Secondary action
Destructive action
Timer start
Timer stop
Toolbar icon action
```

Button rules:

```text
Primary uses the primary gradient
Height is usually 40px
Corner radius is about 10px
Primary text is white
Secondary actions are translucent or low-emphasis, not flat default buttons
Danger actions use the error palette
Only one visually dominant primary action per focus area
```

Timer start/stop buttons must be visually obvious and easy to click.

## Inputs, forms, and toggles

Forms must feel breathable and structured.

Rules:

```text
Field structure: label, input, hint
Field gap: 16px
Label to input gap: 6-8px
Do not create dense spreadsheet-like forms
Avoid too many columns unless the data truly requires it
```

Input style:

```text
Use dark translucent fills in dark mode
Use soft border substitutes
Focus state uses the primary accent and soft focus glow
```

Toggle style:

```text
On: primary accent with glow
Off: dark neutral surface such as #1E293B
```

Tags and pills:

```text
Rounded capsule shape
Tinted background based on semantic or project color
Readable brighter foreground
```

## Tables

Tables should feel productive, airy, and controlled.

Rules:

```text
Right-align durations and money
Use monospaced digits for numbers
Show empty states
Support sorting where useful
Support row expansion for reports and calendar
Avoid overloaded rows
Keep row height around 48-56px where possible
Left side: identity
Center: core information
Right side: actions
Hover uses a soft translucent highlight
```

Do not turn rows into visually noisy control panels.

## Charts

Use Swift Charts, but style them to match the system rather than default chart appearance.

Composition rules:

```text
One chart = one metric
Do not mix income and time in the same chart unless explicitly justified
Use grouped placement such as one large chart plus a small chart row, or multiple balanced cards
Typical chart card height: 160-220px
Title sits top-left
Legend sits right or bottom when needed
Tooltip is required when practical
```

Visual rules:

```text
Lines should be brighter than surrounding UI
Prefer smooth visual flow over harsh angular shapes
At most 1-2 lines per line chart unless necessary
Grid lines are very subtle
Tooltip uses a dark translucent surface with a subtle highlight edge
Donut charts use saturated segments and a darker center
```

Use accent glow on highlighted data in dark mode.

## Navigation and focus states

Interactive state rules:

```text
Active = gradient + glow
Selected = tinted background or subtle outline + accent emphasis
Hover = light translucent lift
Focused inputs and controls = visible accent ring or glow
```

Navigation, selected calendar days, and focused table rows should all follow the same visual logic.

## Materials

Use native macOS materials where possible, but style them through the system tokens instead of relying on default appearance.

Create reusable surface components instead of repeating modifiers.

Example intent:

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
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.large, style: .continuous))
    }
}
```

Any production implementation should also add the repository's shadow, tint, and highlight treatment rather than stopping at plain material.

## Empty states

Every major screen needs a useful empty state with proper hierarchy and breathing room.

Rules:

```text
Short title
Helpful explanation
One clear primary action
Optional supporting secondary action
Enough empty space to feel intentional, not broken
```

Examples should also be written in Russian in the app UI.

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
14. Glass gradient polish and advanced charts.

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
It follows the repository's strict Glass SaaS gradient design language
```

---

# Final instruction for Codex

When in doubt, optimize for:

```text
Data safety
Correct income calculation
Native macOS experience
Strict Glass SaaS gradient visual consistency
Readable senior-level Swift code
Reusable feature architecture
Simple, testable business logic
```
