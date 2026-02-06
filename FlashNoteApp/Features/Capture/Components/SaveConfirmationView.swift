import SwiftUI

struct SaveConfirmationView: View {
    @Binding var isVisible: Bool

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            }
        }
    }
}
