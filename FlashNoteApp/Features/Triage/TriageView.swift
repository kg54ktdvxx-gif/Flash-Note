import SwiftUI
import SwiftData
import FlashNoteCore

struct TriageView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TriageViewModel()

    var body: some View {
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
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(3)
                        }
                        .scaleEffect(0.95)
                        .opacity(0.5)
                    }

                    TriageCardView(note: note) { action in
                        DependencyContainer.shared.hapticService.triageAction()
                        viewModel.performAction(action, context: modelContext)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)

                // Swipe legend
                swipeLegend
            }

            Spacer()
        }
        .padding(.top, AppSpacing.md)
        .navigationTitle("Triage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.undo(context: modelContext)
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(viewModel.undoStack.isEmpty)
            }
        }
        .onAppear {
            viewModel.loadNotes(context: modelContext)
        }
    }

    private var triageCompleteView: some View {
        ContentUnavailableView {
            Label("All Caught Up", systemImage: "checkmark.seal.fill")
        } description: {
            Text("You've triaged all your recent notes. Nice work!")
                .font(AppTypography.body)
        }
        .padding(.top, AppSpacing.xxxl)
    }

    private var swipeLegend: some View {
        HStack(spacing: AppSpacing.xl) {
            legendItem(icon: "arrow.left", label: "Archive", color: AppColors.archiveGray)
            legendItem(icon: "arrow.up", label: "Task", color: AppColors.taskOrange)
            legendItem(icon: "arrow.right", label: "Keep", color: AppColors.keepGreen)
        }
        .font(AppTypography.caption)
        .padding(.top, AppSpacing.sm)
    }

    private func legendItem(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xxxs) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
