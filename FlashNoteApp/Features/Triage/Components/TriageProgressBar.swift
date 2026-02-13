import SwiftUI

struct TriageProgressBar: View {
    let progress: Double
    let remaining: Int

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            // Editorial thin progress line
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.border)
                        .frame(height: 1.5)

                    Rectangle()
                        .fill(AppColors.textPrimary)
                        .frame(width: geometry.size.width * progress, height: 1.5)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 1.5)

            Text("\(remaining) remaining")
                .font(AppTypography.captionSmall)
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
