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

            // The card
            GlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(note.text)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(8)
                        .lineSpacing(3)

                    EditorialRule()

                    HStack(spacing: 0) {
                        Text(note.source.displayName.lowercased())
                            .foregroundStyle(AppColors.textTertiary)

                        Text(" \u{00B7} ")
                            .foregroundStyle(AppColors.textTertiary)

                        Text(note.relativeTimestamp)
                            .foregroundStyle(AppColors.textTertiary)

                        Spacer()
                    }
                    .font(AppTypography.captionSmall)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Note: \(note.text)")
            .accessibilityHint("Swipe right to keep, left to archive, or up to make a task")
            .accessibilityAction(named: "Keep") { onAction(.keep) }
            .accessibilityAction(named: "Archive") { onAction(.archive) }
            .accessibilityAction(named: "Make Task") { onAction(.task) }
            .offset(x: offset.width, y: verticalOffset)
            .rotationEffect(.degrees(Double(offset.width / 25)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        verticalOffset = min(gesture.translation.height, 0)

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
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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

        withAnimation(.easeIn(duration: 0.2)) {
            offset = flyAway
            if action == .task { verticalOffset = -500 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            offset = .zero
            verticalOffset = 0
            onAction(action)
        }
    }
}
