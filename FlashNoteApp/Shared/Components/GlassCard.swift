import SwiftUI

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
                    .fill(.ultraThinMaterial)
            }
    }
}
