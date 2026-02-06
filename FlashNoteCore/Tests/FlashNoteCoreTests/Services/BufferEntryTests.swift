import Testing
import Foundation
@testable import FlashNoteCore

@Suite("BufferEntry")
struct BufferEntryTests {

    @Test("JSON encode/decode round-trip preserves all fields")
    func jsonRoundTrip() throws {
        let entry = BufferEntry(text: "Buy milk", source: .siri, audioFileName: "voice.m4a")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BufferEntry.self, from: data)

        #expect(decoded.id == entry.id)
        #expect(decoded.text == "Buy milk")
        #expect(decoded.sourceRaw == "siri")
        #expect(decoded.source == .siri)
        #expect(decoded.audioFileName == "voice.m4a")
        // Dates should be within 1 second (iso8601 loses sub-second precision)
        #expect(abs(decoded.capturedAt.timeIntervalSince(entry.capturedAt)) < 1.0)
    }

    @Test("JSON round-trip without optional audioFileName")
    func jsonRoundTripNoAudio() throws {
        let entry = BufferEntry(text: "Quick thought", source: .keyboard)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BufferEntry.self, from: data)

        #expect(decoded.text == "Quick thought")
        #expect(decoded.source == .keyboard)
        #expect(decoded.audioFileName == nil)
    }

    @Test("each entry gets a unique UUID")
    func uniqueIDs() {
        let a = BufferEntry(text: "a", source: .keyboard)
        let b = BufferEntry(text: "a", source: .keyboard)
        #expect(a.id != b.id)
    }

    @Test("JSONL line format: single line, no embedded newlines")
    func jsonlLineFormat() throws {
        let entry = BufferEntry(text: "Line one\nLine two", source: .share)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        let jsonString = String(data: data, encoding: .utf8)!

        // JSON should escape \n, so the output is a single line
        #expect(!jsonString.contains("\n"))
    }

    @Test("source computed property handles all CaptureSource cases")
    func sourceAllCases() {
        for captureSource in CaptureSource.allCases {
            let entry = BufferEntry(text: "test", source: captureSource)
            #expect(entry.source == captureSource)
            #expect(entry.sourceRaw == captureSource.rawValue)
        }
    }
}
