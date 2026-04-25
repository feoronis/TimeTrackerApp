import SwiftUI

struct SessionListRow: View {
    let session: WorkSession
    let rateText: String
    let incomeText: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.project?.name ?? "Без проекта")
                    .font(.headline)

                Spacer()

                Text(AppFormatters.durationText(from: session.durationSeconds))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(AppFormatters.dateTimeText(session.startTime))
                if let endTime = session.endTime {
                    Text("- \(AppFormatters.timeText(endTime))")
                } else {
                    Text("- Активна")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.md) {
                Text("Ставка: \(rateText)")
                Text("Доход: \(incomeText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let note = session.note, note.isEmpty == false {
                Text(note)
                    .font(.caption)
            }

            if session.tags.isEmpty == false {
                Text(session.tags.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
