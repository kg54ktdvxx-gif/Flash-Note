import SwiftUI

struct SaveConfirmationView: View {
    @Binding var isVisible: Bool
    @State private var dismissTask: Task<Void, Never>?
    @State private var opacity: Double = 0

    var body: some View {
        if isVisible {
            // Editorial confirmation: typographic, no bouncy icons
            VStack(spacing: 4) {
                Text("Saved")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)

                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 24, height: 1.5)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppBorderRadius.md)
                    .fill(AppColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppBorderRadius.md)
                            .stroke(AppColors.border, lineWidth: 0.5)
                    )
            )
            .opacity(opacity)
            .transition(.opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.15)) {
                    opacity = 1.0
                }
                dismissTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.0))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    try? await Task.sleep(for: .seconds(0.3))
                    guard !Task.isCancelled else { return }
                    isVisible = false
                }
            }
            .onDisappear {
                dismissTask?.cancel()
                opacity = 0
            }
        }
    }
}
