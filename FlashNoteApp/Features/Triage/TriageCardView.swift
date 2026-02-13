import SwiftUI
import UIKit
import FlashNoteCore

struct TriageCardView: View {
    let note: Note
    var onAction: (TriageAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var verticalOffset: CGFloat = 0
    @State private var crossedActionThreshold = false
    @State private var crossedCommitThreshold = false

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

                        let isPastAction = abs(gesture.translation.width) > 30
                            || gesture.translation.height < -30
                        let isPastCommit = gesture.translation.width > swipeThreshold
                            || gesture.translation.width < -swipeThreshold
                            || gesture.translation.height < verticalThreshold

                        if isPastAction, !crossedActionThreshold {
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        if isPastCommit, !crossedCommitThreshold {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }

                        crossedActionThreshold = isPastAction
                        crossedCommitThreshold = isPastCommit
                    }
                    .onEnded { gesture in
                        crossedActionThreshold = false
                        crossedCommitThreshold = false

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

        // Reset state synchronously before notifying parent.
        // Parent should use .id(note.id) on TriageCardView so SwiftUI
        // creates a fresh view (with fresh @State) for the next card.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            offset = .zero
            verticalOffset = 0
            onAction(action)
        }
    }
}
