import SwiftUI

struct SaveConfirmationView: View {
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?
    @State private var checkmarkScale: CGFloat = 0.5
    @State private var showRipple = false

    var body: some View {
        if isVisible {
            ZStack {
                // Ripple effect
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: showRipple ? 120 : 60, height: showRipple ? 120 : 60)
                    .opacity(showRipple ? 0 : 0.6)

                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.success)
                        .scaleEffect(checkmarkScale)
                        .symbolEffect(.bounce, value: isVisible)

                    Text("Saved!")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(AppSpacing.lg)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppBorderRadius.lg))
            }
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                // Animate checkmark and ripple
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    showRipple = true
                }

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
                checkmarkScale = 0.5
                showRipple = false
            }
        }
    }
}
