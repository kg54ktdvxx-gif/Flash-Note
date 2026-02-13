import SwiftUI

struct EmptyInboxView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Text("No notes yet")
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textPrimary)

            Text("Switch to Write to capture a thought.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
