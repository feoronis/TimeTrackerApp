import SwiftUI

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: project.iconName ?? "folder")
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(project.name)
                        .font(.headline)

                    if project.isArchived {
                        Text("Архив")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = project.notes, notes.isEmpty == false {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let hourlyRate = project.hourlyRate {
                Text("\(hourlyRate.description)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
