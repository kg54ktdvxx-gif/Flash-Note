import SwiftUI

struct SwipeActionIndicator: View {
    let action: TriageAction
    let intensity: Double

    var body: some View {
        HStack {
            if action == .archive {
                indicator
                Spacer()
            } else if action == .keep {
                Spacer()
                indicator
            } else {
                Spacer()
                indicator
                Spacer()
            }
        }
    }

    private var indicator: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(AppTypography.captionSmall)
                .tracking(2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .opacity(min(intensity * 2, 1.0))
    }

    private var label: String {
        switch action {
        case .keep: "keep"
        case .archive: "archive"
        case .task: "task"
        }
    }

    private var color: Color {
        switch action {
        case .keep: AppColors.keepGreen
        case .archive: AppColors.archiveGray
        case .task: AppColors.taskOrange
        }
    }
}
