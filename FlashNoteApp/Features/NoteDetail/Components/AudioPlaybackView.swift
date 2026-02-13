import SwiftUI
import AVFoundation
import FlashNoteCore

struct AudioPlaybackView: View {
    let audioURL: URL

    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var duration: TimeInterval = 0
    @State private var player: AVAudioPlayer?
    @State private var progressTask: Task<Void, Never>?
    @State private var setupFailed = false

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ProgressView(value: progress, total: max(duration, 1))
                .tint(AppColors.primary)

            HStack {
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(setupFailed ? AppColors.textTertiary : AppColors.primary)
                }
                .disabled(setupFailed)

                Spacer()

                Text(setupFailed ? "Audio unavailable" : DateHelpers.durationString(from: progress) + " / " + DateHelpers.durationString(from: duration))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppBorderRadius.md))
        .onAppear { setupPlayer() }
        .onDisappear { tearDown() }
    }

    private func setupPlayer() {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            setupFailed = true
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.prepareToPlay()
            duration = player?.duration ?? 0
        } catch {
            FNLog.capture.error("Failed to init audio player: \(error)")
            setupFailed = true
        }
    }

    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        player?.play()
        isPlaying = true
        progressTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let player, player.isPlaying else {
                    stopPlayback()
                    return
                }
                progress = player.currentTime
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        cancelProgressTask()
    }

    private func stopPlayback() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        progress = 0
        cancelProgressTask()
    }

    private func tearDown() {
        cancelProgressTask()
        player?.stop()
        player = nil
    }

    private func cancelProgressTask() {
        progressTask?.cancel()
        progressTask = nil
    }
}
