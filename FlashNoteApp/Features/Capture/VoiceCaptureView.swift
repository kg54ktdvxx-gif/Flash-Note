import SwiftUI
import FlashNoteCore

struct VoiceCaptureView: View {
    var onSave: (String, String?, TimeInterval?, Float?) -> Void

    @State private var transcribedText = ""
    @State private var isRecording = false
    @State private var audioLevel: Float = 0
    @State private var audioFileName: String?
    @State private var audioDuration: TimeInterval?
    @State private var confidence: Float?
    @State private var voiceService: OnDeviceVoiceCaptureService?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                VoiceWaveformView(audioLevel: audioLevel, isRecording: isRecording)
                    .padding(.horizontal, AppSpacing.xl)

                // Transcription display
                ScrollView {
                    Text(transcribedText.isEmpty ? "Tap to start speaking..." : transcribedText)
                        .font(AppTypography.captureInput)
                        .foregroundStyle(transcribedText.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                }
                .frame(maxHeight: 200)

                Spacer()

                // Record button
                Button {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? AppColors.deleteRed : AppColors.primary)
                            .frame(width: 72, height: 72)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, AppSpacing.lg)

                // Save button (appears after recording)
                if !transcribedText.isEmpty && !isRecording {
                    Button {
                        onSave(transcribedText, audioFileName, audioDuration, confidence)
                        dismiss()
                    } label: {
                        Label("Save Note", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.primary)
                    .padding(.bottom, AppSpacing.lg)
                }
            }
            .navigationTitle("Voice Capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func startRecording() {
        let service = OnDeviceVoiceCaptureService()
        self.voiceService = service

        Task {
            do {
                let stream = try await service.startCapture()
                isRecording = true

                for await result in stream {
                    transcribedText = result.text
                    confidence = result.confidence
                    audioFileName = result.audioFileName
                    let level = await service.currentAudioLevel()
                    audioLevel = level

                    if result.isFinal {
                        audioDuration = result.audioDuration
                    }
                }
                isRecording = false
            } catch {
                FNLog.voice.error("Voice capture failed: \(error)")
                isRecording = false
            }
        }
    }

    private func stopRecording() {
        Task {
            if let result = await voiceService?.stopCapture() {
                audioDuration = result.audioDuration
            }
            isRecording = false
        }
    }
}
