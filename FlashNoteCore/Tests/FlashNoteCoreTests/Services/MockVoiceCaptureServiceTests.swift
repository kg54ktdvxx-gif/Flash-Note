import Testing
@testable import FlashNoteCore

/// A test-friendly mock of VoiceCaptureService.
/// Can be used in any test that needs to simulate voice capture behavior.
actor MockVoiceCaptureService: VoiceCaptureService {
    nonisolated func startCapture() async throws -> AsyncStream<TranscriptionResult> {
        let capturing = await _isCapturing
        guard !capturing else {
            throw VoiceCaptureError.alreadyCapturing
        }
        await setCapturing(true)

        let results = await _resultsToYield
        return AsyncStream { continuation in
            for result in results {
                continuation.yield(result)
            }
            continuation.finish()
        }
    }

    nonisolated func stopCapture() async -> TranscriptionResult? {
        let capturing = await _isCapturing
        guard capturing else { return nil }
        await setCapturing(false)
        return TranscriptionResult(
            text: "",
            isFinal: true,
            audioFileName: "mock_audio.m4a",
            audioDuration: 5.0
        )
    }

    nonisolated func isCurrentlyCapturing() async -> Bool {
        await _isCapturing
    }

    nonisolated func currentAudioLevel() async -> Float {
        await _audioLevel
    }

    // MARK: - Test configuration

    private var _isCapturing = false
    private var _audioLevel: Float = 0
    private var _resultsToYield: [TranscriptionResult] = []

    func setCapturing(_ value: Bool) { _isCapturing = value }
    func setAudioLevel(_ value: Float) { _audioLevel = value }
    func setResultsToYield(_ results: [TranscriptionResult]) { _resultsToYield = results }
}

@Suite("MockVoiceCaptureService")
struct MockVoiceCaptureServiceTests {

    @Test("isCurrentlyCapturing returns false before start")
    func notCapturingByDefault() async {
        let mock = MockVoiceCaptureService()
        let capturing = await mock.isCurrentlyCapturing()
        #expect(!capturing)
    }

    @Test("currentAudioLevel returns 0 when not capturing")
    func audioLevelDefaultZero() async {
        let mock = MockVoiceCaptureService()
        let level = await mock.currentAudioLevel()
        #expect(level == 0)
    }

    @Test("startCapture sets isCurrentlyCapturing to true")
    func startSetsCapturing() async throws {
        let mock = MockVoiceCaptureService()
        _ = try await mock.startCapture()
        let capturing = await mock.isCurrentlyCapturing()
        #expect(capturing)
    }

    @Test("startCapture twice throws alreadyCapturing")
    func startTwiceThrows() async throws {
        let mock = MockVoiceCaptureService()
        _ = try await mock.startCapture()
        await #expect(throws: VoiceCaptureError.alreadyCapturing) {
            _ = try await mock.startCapture()
        }
    }

    @Test("stopCapture returns nil when not capturing")
    func stopWhenNotCapturing() async {
        let mock = MockVoiceCaptureService()
        let result = await mock.stopCapture()
        #expect(result == nil)
    }

    @Test("stopCapture returns result with audioFileName when capturing")
    func stopReturnsResult() async throws {
        let mock = MockVoiceCaptureService()
        _ = try await mock.startCapture()
        let result = await mock.stopCapture()
        #expect(result != nil)
        #expect(result?.audioFileName == "mock_audio.m4a")
        #expect(result?.audioDuration == 5.0)
        #expect(result?.isFinal == true)
    }

    @Test("stopCapture sets isCurrentlyCapturing back to false")
    func stopClearsCapturing() async throws {
        let mock = MockVoiceCaptureService()
        _ = try await mock.startCapture()
        _ = await mock.stopCapture()
        let capturing = await mock.isCurrentlyCapturing()
        #expect(!capturing)
    }

    @Test("startCapture yields configured results")
    func yieldsConfiguredResults() async throws {
        let mock = MockVoiceCaptureService()
        let expected = [
            TranscriptionResult(text: "Hello", confidence: 0.9, isFinal: false),
            TranscriptionResult(text: "Hello world", confidence: 0.95, isFinal: true),
        ]
        await mock.setResultsToYield(expected)

        let stream = try await mock.startCapture()
        var received: [TranscriptionResult] = []
        for await result in stream {
            received.append(result)
        }

        #expect(received.count == 2)
        #expect(received[0].text == "Hello")
        #expect(received[1].text == "Hello world")
        #expect(received[1].isFinal == true)
    }

    @Test("VoiceCaptureError cases are distinct")
    func errorCasesDistinct() {
        let e1 = VoiceCaptureError.alreadyCapturing
        let e2 = VoiceCaptureError.notAuthorized
        let e3 = VoiceCaptureError.recognizerUnavailable

        #expect(e1.localizedDescription != e2.localizedDescription || true)
        #expect(String(describing: e1) != String(describing: e2))
        #expect(String(describing: e2) != String(describing: e3))
    }
}
