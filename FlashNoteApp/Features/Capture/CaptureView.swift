import SwiftUI
import SwiftData
import FlashNoteCore

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        ZStack {
            AppColors.captureBackground
                .ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(spacing: 0) {
                // Voice mode button
                HStack {
                    Spacer()
                    Button {
                        viewModel.isVoiceMode = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(AppColors.primary)
                            .padding(AppSpacing.sm)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)

                CaptureTextField(text: $viewModel.text)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                bottomBar
            }

            // Save confirmation overlay
            SaveConfirmationView(isVisible: $viewModel.showSaveConfirmation)

            // Post-save banners
            VStack(spacing: AppSpacing.xs) {
                Spacer()

                TaskSuggestionBanner(
                    onAccept: { viewModel.markAsTask(context: modelContext) },
                    isVisible: $viewModel.showTaskSuggestion
                )

                MergePromptBanner(
                    onMerge: { viewModel.mergeWithPrevious(context: modelContext) },
                    onDismiss: { viewModel.dismissMerge() },
                    isVisible: $viewModel.showMergePrompt
                )
            }
            .padding(.bottom, 80) // Above bottom bar
        }
        .sheet(isPresented: $viewModel.isVoiceMode) {
            VoiceCaptureView(onSave: { text, audioFile, duration, confidence in
                viewModel.saveVoiceNote(
                    text: text,
                    audioFileName: audioFile,
                    audioDuration: duration,
                    confidence: confidence,
                    context: modelContext
                )
            })
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            viewModel.handlePrefill(router.prefillText)
            router.prefillText = nil
        }
        .onChange(of: viewModel.text) {
            viewModel.scheduleDraftSave()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background || scenePhase == .inactive {
                viewModel.saveDraft()
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private var bottomBar: some View {
        HStack {
            Text(viewModel.canSave ? "\(viewModel.text.count) chars" : "")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)

            Spacer()

            Button {
                viewModel.save(context: modelContext)
            } label: {
                Label("Save", systemImage: "arrow.up.circle.fill")
                    .font(AppTypography.headline)
            }
            .disabled(!viewModel.canSave)
            .buttonStyle(.primary)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.darkSurface)
    }
}
