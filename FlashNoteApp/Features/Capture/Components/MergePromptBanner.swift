import SwiftUI

struct MergePromptBanner: View {
    let onMerge: () -> Void
    let onDismiss: () -> Void
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isVisible {
            HStack(spacing: AppSpacing.xs) {
                Text("Combine with previous note?")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button {
                    onMerge()
                    dismiss()
                } label: {
                    Text("Merge")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.primary)
                }

                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.darkElevated, in: RoundedRectangle(cornerRadius: AppBorderRadius.md))
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
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
