import SwiftUI
import SwiftData
import FlashNoteCore

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.captureBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    CaptureTextField(text: $viewModel.text)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.sm)

                    bottomBar
                }

                SaveConfirmationView(isVisible: $viewModel.showSaveConfirmation)
            }
            .navigationTitle("Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.isVoiceMode = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                    }
                }
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
        }
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
        .background(.bar)
    }
}
