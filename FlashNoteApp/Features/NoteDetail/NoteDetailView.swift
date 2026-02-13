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
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Source + timestamp — monospace metadata
                    HStack(spacing: 0) {
                        Text(note.source.displayName.lowercased())
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        Text(" \u{00B7} ")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        Text(DateFormatters.fullTimestamp(for: note.createdAt))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        Spacer()
                    }

                    EditorialRule()

                    // Note text — serif for reading
                    if viewModel.isEditing {
                        TextEditor(text: $viewModel.editedText)
                            .font(AppTypography.captureInput)
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                    } else {
                        Text(note.text)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(AppColors.textPrimary)
                            .textSelection(.enabled)
                            .lineSpacing(4)
                    }

                    // Audio playback
                    if let audioURL = note.audioURL {
                        AudioPlaybackView(audioURL: audioURL)
                    }

                    // Edit timestamp
                    if note.updatedAt != note.createdAt {
                        EditorialRule()
                        Text("edited \(DateFormatters.relativeTimestamp(for: note.updatedAt))")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                .padding(AppSpacing.screenHorizontal)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.isEditing {
                    Button("Cancel") { viewModel.cancelEdit() }
                        .foregroundStyle(AppColors.textSecondary)
                    Button("Save") { viewModel.saveEdit(context: modelContext) }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.accent)
                } else {
                    Menu {
                        Button {
                            viewModel.isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            viewModel.togglePin(context: modelContext)
                        } label: {
                            Label(
                                note.isPinned ? "Unpin" : "Pin",
                                systemImage: note.isPinned ? "pin.slash" : "pin"
                            )
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
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
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
