import SwiftUI

struct TaskSuggestionBanner: View {
    let onAccept: () -> Void
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isVisible {
            HStack(spacing: AppSpacing.xs) {
                Text("TASK DETECTED")
                    .font(AppTypography.captionSmall)
                    .tracking(1)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button {
                    onAccept()
                    dismiss()
                } label: {
                    Text("MARK")
                        .font(AppTypography.captionSmall)
                        .tracking(1)
                        .foregroundStyle(AppColors.taskOrange)
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
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
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
