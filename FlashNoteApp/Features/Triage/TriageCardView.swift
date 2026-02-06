import SwiftUI
import FlashNoteCore

struct TriageCardView: View {
    let note: Note
    var onAction: (TriageAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var verticalOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 100
    private let verticalThreshold: CGFloat = -80

    var body: some View {
        ZStack {
            // Action indicators behind the card
            if let action = currentAction {
                SwipeActionIndicator(
                    action: action,
                    intensity: swipeIntensity
                )
                .padding(.horizontal, AppSpacing.xl)
            }

            // The card itself
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(note.text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(8)

                    HStack {
                        Label(note.source.displayName, systemImage: note.source.iconName)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        Spacer()

                        Text(note.relativeTimestamp)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .offset(x: offset.width, y: verticalOffset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        verticalOffset = min(gesture.translation.height, 0) // Only allow upward
                    }
                    .onEnded { gesture in
                        if gesture.translation.width > swipeThreshold {
                            completeSwipe(.keep)
                        } else if gesture.translation.width < -swipeThreshold {
                            completeSwipe(.archive)
                        } else if gesture.translation.height < verticalThreshold {
                            completeSwipe(.task)
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                                verticalOffset = 0
                            }
                        }
                    }
            )
        }
    }

    private var currentAction: TriageAction? {
        if offset.width > 30 { return .keep }
        if offset.width < -30 { return .archive }
        if verticalOffset < -30 { return .task }
        return nil
    }

    private var swipeIntensity: Double {
        let horizontal = abs(Double(offset.width)) / Double(swipeThreshold)
        let vertical = abs(Double(verticalOffset)) / Double(abs(verticalThreshold))
        return max(horizontal, vertical)
    }

    private func completeSwipe(_ action: TriageAction) {
        let flyAway: CGSize
        switch action {
        case .keep:
            flyAway = CGSize(width: 500, height: 0)
        case .archive:
            flyAway = CGSize(width: -500, height: 0)
        case .task:
            flyAway = CGSize(width: 0, height: -500)
        }

        withAnimation(.easeIn(duration: 0.25)) {
            offset = flyAway
            if action == .task { verticalOffset = -500 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onAction(action)
            offset = .zero
            verticalOffset = 0
        }
    }
}
