import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search notes..."

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(AppTypography.body)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppBorderRadius.textField))
    }
}
