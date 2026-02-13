import SwiftUI
import FlashNoteCore

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }

                Text(note.previewText)
                    .font(AppTypography.notePreview)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                Spacer()

                if note.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            HStack(spacing: AppSpacing.xs) {
                Image(systemName: note.source.iconName)
                    .font(.caption2)
                    .foregroundStyle(AppColors.textTertiary)

                Text(note.relativeTimestamp)
                    .font(AppTypography.noteTimestamp)
                    .foregroundStyle(AppColors.textTertiary)

                Text("·")
                    .font(AppTypography.noteTimestamp)
                    .foregroundStyle(AppColors.textTertiary)

                Text("\(note.wordCount) words")
                    .font(AppTypography.noteTimestamp)
                    .foregroundStyle(AppColors.textTertiary)

                if note.isTask {
                    Label("Task", systemImage: note.isTaskCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                        .foregroundStyle(note.isTaskCompleted ? AppColors.success : AppColors.taskOrange)
                }

                Spacer()
            }
        }
        .padding(.vertical, AppSpacing.xxs)
        .contentShape(Rectangle())
    }
}
