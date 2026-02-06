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
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: iconName)
                .font(.system(size: 32))
            Text(label)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .opacity(min(intensity * 2, 1.0))
        .scaleEffect(0.8 + min(intensity, 1.0) * 0.2)
    }

    private var iconName: String {
        switch action {
        case .keep: "checkmark.circle.fill"
        case .archive: "archivebox.fill"
        case .task: "arrow.up.circle.fill"
        }
    }

    private var label: String {
        switch action {
        case .keep: "Keep"
        case .archive: "Archive"
        case .task: "Task"
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
