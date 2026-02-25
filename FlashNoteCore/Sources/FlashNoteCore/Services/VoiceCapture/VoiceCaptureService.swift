import Foundation
#if canImport(Speech)
import Speech
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

public protocol VoiceCaptureService: Sendable {
    func startCapture() async throws -> AsyncStream<TranscriptionResult>
    func stopCapture() async -> TranscriptionResult?
    func isCurrentlyCapturing() async -> Bool
    func currentAudioLevel() async -> Float
}

#if canImport(Speech) && canImport(AVFoundation) && os(iOS)
public final class OnDeviceVoiceCaptureService: VoiceCaptureService, @unchecked Sendable {
    private let lock = NSLock()

    // All mutable state — only access inside lock.withLock { }
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var audioRecorder: AVAudioRecorder?
    private var _audioFileName: String?
    private var recordingStartTime: Date?
    private var _isCapturing = false
    private var _audioLevel: Float = 0

    public init() {
        self.recognizer = SFSpeechRecognizer(locale: .current)
    }

    public func isCurrentlyCapturing() async -> Bool {
        lock.withLock { _isCapturing }
    }

    public func currentAudioLevel() async -> Float {
        lock.withLock { _audioLevel }
    }

    public func startCapture() async throws -> AsyncStream<TranscriptionResult> {
        let isCapturing = lock.withLock { _isCapturing }
        guard !isCapturing else {
            throw VoiceCaptureError.alreadyCapturing
        }

        let authStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard authStatus == .authorized else {
            throw VoiceCaptureError.notAuthorized
        }

        let recognizer = lock.withLock { self.recognizer }
        guard let recognizer, recognizer.isAvailable else {
            throw VoiceCaptureError.recognizerUnavailable
        }

        let fileName = "\(UUID().uuidString).m4a"
        let audioURL = AppGroupContainer.audioFileURL(for: fileName)
        let recordingSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: audioURL, settings: recordingSettings)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

        let engine = AVAudioEngine()

        // Store all state inside lock
        lock.withLock {
            _isCapturing = true
            _audioFileName = fileName
            self.audioRecorder = recorder
            self.recognitionRequest = request
            self.audioEngine = engine
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        lock.withLock { recordingStartTime = .now }
        recorder.record()

        let serviceLock = self.lock
        let stream = AsyncStream<TranscriptionResult> { continuation in
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
                if let channelData = buffer.floatChannelData?[0] {
                    let frameLength = Int(buffer.frameLength)
                    var sum: Float = 0
                    for i in 0..<frameLength {
                        sum += abs(channelData[i])
                    }
                    let avg = sum / Float(max(frameLength, 1))
                    serviceLock.withLock { [weak self] in
                        self?._audioLevel = avg
                    }
                }
            }

            let task = recognizer.recognitionTask(with: request) { result, error in
                if let result {
                    let transcription = TranscriptionResult(
                        text: result.bestTranscription.formattedString,
                        confidence: result.bestTranscription.segments.last?.confidence ?? 0,
                        isFinal: result.isFinal,
                        audioFileName: fileName
                    )
                    continuation.yield(transcription)

                    if result.isFinal {
                        continuation.finish()
                    }
                }

                if let error {
                    FNLog.voice.error("Recognition error: \(error)")
                    let errorResult = TranscriptionResult(
                        text: "",
                        isFinal: true,
                        errorMessage: "Speech recognition couldn't process your audio. Please try again."
                    )
                    continuation.yield(errorResult)
                    continuation.finish()
                }
            }
            serviceLock.withLock { [weak self] in
                self?.recognitionTask = task
            }

            do {
                engine.prepare()
                try engine.start()
            } catch {
                FNLog.voice.error("Audio engine failed to start: \(error)")
                // Clean up everything since we claimed _isCapturing = true
                self.tearDownCaptureResources(deleteOrphanedAudio: true)
                continuation.finish()
            }
        }

        return stream
    }

    public func stopCapture() async -> TranscriptionResult? {
        let isCapturing = lock.withLock { _isCapturing }
        guard isCapturing else { return nil }

        let (fileName, startTime) = lock.withLock {
            (_audioFileName, recordingStartTime)
        }

        let duration: TimeInterval?
        if let startTime {
            duration = Date.now.timeIntervalSince(startTime)
        } else {
            duration = nil
        }

        tearDownCaptureResources()

        if let fileName {
            return TranscriptionResult(
                text: "",
                isFinal: true,
                audioFileName: fileName,
                audioDuration: duration
            )
        }
        return nil
    }

    /// Tears down audio engine, recorder, recognition, and resets state flags.
    /// Safe to call multiple times.
    /// - Parameter deleteOrphanedAudio: If `true`, deletes the recorded audio file.
    ///   Only pass `true` from error paths where the audio won't be used.
    private func tearDownCaptureResources(deleteOrphanedAudio: Bool = false) {
        // Grab references inside lock, then operate outside to avoid deadlock
        let (engine, request, task, recorder, fileName) = lock.withLock {
            let refs = (audioEngine, recognitionRequest, recognitionTask, audioRecorder, _audioFileName)
            _isCapturing = false
            _audioLevel = 0
            _audioFileName = nil
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
            audioRecorder = nil
            recordingStartTime = nil
            return refs
        }

        engine?.stop()
        engine?.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        recorder?.stop()

        if deleteOrphanedAudio, let fileName {
            let url = AppGroupContainer.audioFileURL(for: fileName)
            try? FileManager.default.removeItem(at: url)
            FNLog.voice.info("Cleaned up orphaned audio: \(fileName)")
        }
    }
}
#endif

public enum VoiceCaptureError: Error, Sendable {
    case alreadyCapturing
    case notAuthorized
    case recognizerUnavailable
}
