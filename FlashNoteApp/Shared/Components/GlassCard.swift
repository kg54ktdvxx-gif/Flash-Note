import SwiftUI

/// Editorial card: thin border, sharp corners, no blur or glass effects.
/// Relies on typography and spacing for hierarchy, not surface decoration.
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPadding)
            .background {
                RoundedRectangle(cornerRadius: AppBorderRadius.card)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppBorderRadius.card)
                            .stroke(AppColors.border, lineWidth: 0.5)
                    )
            }
    }
}

/// Horizontal rule for editorial section dividers.
struct EditorialRule: View {
    var weight: CGFloat = 0.5
    var color: Color = AppColors.divider

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: weight)
    }
}

/// Thick rule for major section breaks (editorial double-rule style).
struct EditorialHeavyRule: View {
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(AppColors.rule)
                .frame(height: 2)
            Rectangle()
                .fill(AppColors.rule)
                .frame(height: 0.5)
        }
    }
}
