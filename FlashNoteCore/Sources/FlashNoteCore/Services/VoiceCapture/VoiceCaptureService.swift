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

        guard let recognizer, recognizer.isAvailable else {
            throw VoiceCaptureError.recognizerUnavailable
        }

        lock.withLock { _isCapturing = true }

        let fileName = "\(UUID().uuidString).m4a"
        lock.withLock { _audioFileName = fileName }
        let audioURL = AppGroupContainer.audioFileURL(for: fileName)
        let recordingSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: audioURL, settings: recordingSettings)
        self.audioRecorder = recorder

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.recognitionRequest = request

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        recordingStartTime = .now
        recorder.record()

        let serviceLock = self.lock
        let stream = AsyncStream<TranscriptionResult> { continuation in
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                request.append(buffer)
                if let channelData = buffer.floatChannelData?[0] {
                    let frameLength = Int(buffer.frameLength)
                    var sum: Float = 0
                    for i in 0..<frameLength {
                        sum += abs(channelData[i])
                    }
                    let avg = sum / Float(frameLength)
                    serviceLock.withLock {
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
                    continuation.finish()
                }
            }
            self.recognitionTask = task

            do {
                engine.prepare()
                try engine.start()
            } catch {
                FNLog.voice.error("Audio engine failed to start: \(error)")
                continuation.finish()
            }
        }

        return stream
    }

    public func stopCapture() async -> TranscriptionResult? {
        let isCapturing = lock.withLock { _isCapturing }
        guard isCapturing else { return nil }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioRecorder?.stop()

        let duration: TimeInterval?
        if let start = recordingStartTime {
            duration = Date.now.timeIntervalSince(start)
        } else {
            duration = nil
        }

        let fileName = lock.withLock { () -> String? in
            _isCapturing = false
            _audioLevel = 0
            let name = _audioFileName
            _audioFileName = nil
            return name
        }

        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        recordingStartTime = nil

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
}
#endif

public enum VoiceCaptureError: Error, Sendable {
    case alreadyCapturing
    case notAuthorized
    case recognizerUnavailable
}
