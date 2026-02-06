import SwiftUI

struct SaveConfirmationView: View {
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        if isVisible {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.success)
                    .symbolEffect(.bounce, value: isVisible)

                Text("Saved")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(AppSpacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppBorderRadius.lg))
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            }
            .onDisappear {
                dismissTask?.cancel()
            }
        }
    }
}
