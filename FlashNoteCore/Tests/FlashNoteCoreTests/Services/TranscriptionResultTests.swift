import Testing
import Foundation
@testable import FlashNoteCore

@Suite("TranscriptionResult")
struct TranscriptionResultTests {
    @Test("default values")
    func defaults() {
        let result = TranscriptionResult(text: "Hello")
        #expect(result.text == "Hello")
        #expect(result.confidence == 1.0)
        #expect(result.isFinal == false)
        #expect(result.audioFileName == nil)
        #expect(result.audioDuration == nil)
    }

    @Test("all parameters")
    func allParams() {
        let result = TranscriptionResult(
            text: "Test",
            confidence: 0.85,
            isFinal: true,
            audioFileName: "recording.m4a",
            audioDuration: 30.5
        )
        #expect(result.text == "Test")
        #expect(result.confidence == 0.85)
        #expect(result.isFinal == true)
        #expect(result.audioFileName == "recording.m4a")
        #expect(result.audioDuration == 30.5)
    }

    @Test("empty text is allowed")
    func emptyText() {
        let result = TranscriptionResult(text: "")
        #expect(result.text == "")
    }

    @Test("Sendable conformance")
    func sendable() {
        let result = TranscriptionResult(text: "test")
        let _: any Sendable = result
        #expect(true)
    }
}
