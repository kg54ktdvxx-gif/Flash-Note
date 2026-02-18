import SwiftUI
import SwiftData
import FlashNoteCore

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = CaptureViewModel()
    @State private var isChecklistMode = false

    var body: some View {
        ZStack {
            AppColors.captureBackground
                .ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(spacing: 0) {
                // Mode toggle — checklist on/off
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isChecklistMode.toggle()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: isChecklistMode ? "checklist.checked" : "checklist")
                                .font(.system(size: 14, weight: .medium))
                            if isChecklistMode {
                                Text("LIST")
                                    .font(AppTypography.captionSmall)
                                    .tracking(1)
                            }
                        }
                        .foregroundStyle(isChecklistMode ? AppColors.accent : AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 6)
                    }
                    .accessibilityLabel(isChecklistMode ? "Disable checklist mode" : "Enable checklist mode")
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)

                // Editor — text or checklist
                if isChecklistMode {
                    ChecklistEditor(text: $viewModel.text)
                        .frame(maxHeight: .infinity)
                } else {
                    CaptureTextField(text: $viewModel.text)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                }

                EditorialRule()

                captureBottomBar
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
            .padding(.bottom, 72) // Above bottom bar
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

    private var captureBottomBar: some View {
        HStack {
            // Character count in monospace
            Text(viewModel.canSave ? "\(viewModel.text.count)" : "")
                .font(AppTypography.captionSmall)
                .foregroundStyle(AppColors.textTertiary)

            Spacer()

            Button {
                viewModel.save(context: modelContext)
                if isChecklistMode {
                    isChecklistMode = false
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Save")
                        .font(AppTypography.caption)
                        .tracking(1)
                        .textCase(.uppercase)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .disabled(!viewModel.canSave)
            .buttonStyle(.primary)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.background)
    }
}
