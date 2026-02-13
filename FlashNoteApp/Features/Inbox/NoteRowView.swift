import SwiftUI
import FlashNoteCore

struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            // Note text — clean, undecorated
            HStack(alignment: .top) {
                if note.isPinned {
                    Rectangle()
                        .fill(AppColors.accent)
                        .frame(width: 2)
                        .padding(.trailing, 4)
                }

                Text(note.previewText)
                    .font(AppTypography.notePreview)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: 8)

                if note.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            // Metadata line — monospace, compact
            HStack(spacing: 0) {
                Text(note.source.displayName.lowercased())
                    .foregroundStyle(AppColors.textTertiary)

                Text(" \u{00B7} ")
                    .foregroundStyle(AppColors.textTertiary)

                Text(note.relativeTimestamp)
                    .foregroundStyle(AppColors.textTertiary)

                Text(" \u{00B7} ")
                    .foregroundStyle(AppColors.textTertiary)

                Text("\(note.wordCount)w")
                    .foregroundStyle(AppColors.textTertiary)

                if note.isTask {
                    Text(" \u{00B7} ")
                        .foregroundStyle(AppColors.textTertiary)

                    Text(note.isTaskCompleted ? "done" : "task")
                        .foregroundStyle(note.isTaskCompleted ? AppColors.success : AppColors.taskOrange)
                }

                Spacer()
            }
            .font(AppTypography.noteTimestamp)
        }
        .padding(.vertical, AppSpacing.xs)
        .contentShape(Rectangle())
    }
}
