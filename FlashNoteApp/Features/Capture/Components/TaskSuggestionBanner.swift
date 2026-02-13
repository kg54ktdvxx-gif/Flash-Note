import SwiftUI

struct TaskSuggestionBanner: View {
    let onAccept: () -> Void
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isVisible {
            HStack(spacing: AppSpacing.xs) {
                Text("Looks like a task")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Button {
                    onAccept()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(AppColors.taskOrange)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColors.darkElevated, in: RoundedRectangle(cornerRadius: AppBorderRadius.md))
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
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
