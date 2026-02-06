import SwiftUI

struct TriageProgressBar: View {
    let progress: Double
    let remaining: Int

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            ProgressView(value: progress)
                .tint(AppColors.primary)

            Text("\(remaining) remaining")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
