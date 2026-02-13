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
    @State private var errorMessage: String?
    @State private var recordingTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Spacer()

                VoiceWaveformView(audioLevel: audioLevel, isRecording: isRecording)
                    .padding(.horizontal, AppSpacing.xl)

                // Transcription display — serif for editorial feel
                ScrollView {
                    Text(transcribedText.isEmpty ? "Tap to start speaking..." : transcribedText)
                        .font(AppTypography.captureInput)
                        .foregroundStyle(transcribedText.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                }
                .frame(maxHeight: 200)

                Spacer()

                // Record button — sharp circle, accent color
                Button {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(isRecording ? AppColors.accent : AppColors.textPrimary)
                            .frame(width: 64, height: 64)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(isRecording ? .white : AppColors.background)
                    }
                }
                .padding(.bottom, AppSpacing.lg)

                // Save button
                if !transcribedText.isEmpty && !isRecording {
                    Button {
                        onSave(transcribedText, audioFileName, audioDuration, confidence)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Save")
                                .font(AppTypography.caption)
                                .tracking(1)
                                .textCase(.uppercase)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .buttonStyle(.primary)
                    .padding(.bottom, AppSpacing.lg)
                }
            }
            .background(AppColors.background)
            .navigationTitle("Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .onDisappear { recordingTask?.cancel() }
            .alert("Voice Capture Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func startRecording() {
        errorMessage = nil
        let service = OnDeviceVoiceCaptureService()
        self.voiceService = service

        recordingTask = Task { @MainActor in
            do {
                let stream = try await service.startCapture()
                isRecording = true

                for await result in stream {
                    if Task.isCancelled { break }
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
            } catch let error as VoiceCaptureError {
                isRecording = false
                switch error {
                case .notAuthorized:
                    errorMessage = "Microphone or speech recognition permission is required. Enable it in Settings."
                case .recognizerUnavailable:
                    errorMessage = "Speech recognition is not available on this device."
                case .alreadyCapturing:
                    errorMessage = "A recording is already in progress."
                }
            } catch {
                FNLog.voice.error("Voice capture failed: \(error)")
                isRecording = false
                errorMessage = "Voice capture failed. Please try again."
            }
        }
    }

    private func stopRecording() {
        Task { @MainActor in
            if let result = await voiceService?.stopCapture() {
                audioDuration = result.audioDuration
            }
            isRecording = false
        }
    }
}
