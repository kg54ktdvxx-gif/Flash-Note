import SwiftUI
import SwiftData
import FlashNoteCore

struct TriageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TriageViewModel()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                TriageProgressBar(progress: viewModel.progress, remaining: viewModel.remaining)
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                if viewModel.isComplete {
                    triageCompleteView
                } else if let note = viewModel.currentNote {
                    ZStack {
                        // Next card preview (behind)
                        if viewModel.currentIndex + 1 < viewModel.triageNotes.count {
                            let nextNote = viewModel.triageNotes[viewModel.currentIndex + 1]
                            GlassCard {
                                Text(nextNote.previewText)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textTertiary)
                                    .lineLimit(3)
                            }
                            .scaleEffect(0.97)
                            .opacity(0.4)
                        }

                        TriageCardView(note: note) { action in
                            DependencyContainer.shared.hapticService.triageAction()
                            viewModel.performAction(action, context: modelContext)
                        }
                        .id(note.id)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    // Swipe legend — monospace, understated
                    swipeLegend
                }

                Spacer()
            }
            .padding(.top, AppSpacing.md)
        }
        .navigationTitle("Triage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColors.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.undo(context: modelContext)
                } label: {
                    Text("UNDO")
                        .font(AppTypography.captionSmall)
                        .tracking(1)
                        .foregroundStyle(viewModel.undoStack.isEmpty ? AppColors.textTertiary : AppColors.textSecondary)
                }
                .disabled(viewModel.undoStack.isEmpty)
            }
        }
        .onAppear {
            viewModel.loadNotes(context: modelContext)
        }
    }

    private var triageCompleteView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Text("All caught up")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)

            Text("Every note has been triaged.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)

            Spacer()
        }
    }

    private var swipeLegend: some View {
        HStack(spacing: AppSpacing.xl) {
            legendItem(direction: "\u{2190}", label: "archive", color: AppColors.archiveGray)
            legendItem(direction: "\u{2191}", label: "task", color: AppColors.taskOrange)
            legendItem(direction: "\u{2192}", label: "keep", color: AppColors.keepGreen)
        }
        .font(AppTypography.captionSmall)
        .padding(.top, AppSpacing.sm)
    }

    private func legendItem(direction: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(direction)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
