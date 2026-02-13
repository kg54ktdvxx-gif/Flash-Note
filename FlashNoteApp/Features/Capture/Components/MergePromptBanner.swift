import SwiftUI

struct MergePromptBanner: View {
    let onMerge: () -> Void
    let onDismiss: () -> Void
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isVisible {
            HStack(spacing: AppSpacing.xs) {
                Text("Combine with previous?")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button {
                    onMerge()
                    dismiss()
                } label: {
                    Text("MERGE")
                        .font(AppTypography.captionSmall)
                        .tracking(1)
                        .foregroundStyle(AppColors.accent)
                }

                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AppBorderRadius.md)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppBorderRadius.md)
                            .stroke(AppColors.border, lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(5))
                    guard !Task.isCancelled else { return }
                    onDismiss()
                    dismiss()
                }
            }
            .onDisappear {
                dismissTask?.cancel()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
    }
}
