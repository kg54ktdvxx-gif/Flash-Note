import SwiftUI
import SwiftData
import FlashNoteCore

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NoteDetailViewModel

    let note: Note

    init(note: Note) {
        self.note = note
        self._viewModel = State(initialValue: NoteDetailViewModel(note: note))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Source badge + timestamp
                HStack(spacing: AppSpacing.xs) {
                    Label(note.source.displayName, systemImage: note.source.iconName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxxs)
                        .background(AppColors.primarySoft, in: Capsule())

                    Spacer()

                    Text(DateFormatters.fullTimestamp(for: note.createdAt))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }

                // Note text
                if viewModel.isEditing {
                    TextEditor(text: $viewModel.editedText)
                        .font(AppTypography.body)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                } else {
                    Text(note.text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .textSelection(.enabled)
                }

                // Audio playback
                if let audioURL = note.audioURL {
                    AudioPlaybackView(audioURL: audioURL)
                }

                // Metadata
                if note.updatedAt != note.createdAt {
                    Text("Edited \(DateFormatters.relativeTimestamp(for: note.updatedAt))")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.screenHorizontal)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    Button("Cancel") { viewModel.cancelEdit() }
                    Button("Save") { viewModel.saveEdit(context: modelContext) }
                        .fontWeight(.semibold)
                } else {
                    Menu {
                        Button {
                            viewModel.isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            viewModel.toggleTask(context: modelContext)
                        } label: {
                            Label(
                                note.isTask ? "Toggle Complete" : "Mark as Task",
                                systemImage: note.isTask ? "checkmark.circle" : "circle"
                            )
                        }

                        Button {
                            viewModel.showExport = true
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showExport) {
            ExportActionSheet(note: note, isPresented: $viewModel.showExport)
        }
        .alert("Delete Note?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteNote(context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This note will be moved to trash.")
        }
    }
}
