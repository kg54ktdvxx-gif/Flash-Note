import Testing
@testable import FlashNoteCore

@Suite("BufferEntry Length Cap")
struct BufferEntryLengthTests {

    @Test("short text is not truncated")
    func shortTextUnchanged() {
        let entry = BufferEntry(text: "Hello world", source: .keyboard)
        #expect(entry.text == "Hello world")
    }

    @Test("text at maxTextLength is not truncated")
    func exactLimitUnchanged() {
        let text = String(repeating: "a", count: BufferEntry.maxTextLength)
        let entry = BufferEntry(text: text, source: .keyboard)
        #expect(entry.text.count == BufferEntry.maxTextLength)
    }

    @Test("text exceeding maxTextLength is truncated")
    func exceedingLimitTruncated() {
        let text = String(repeating: "b", count: BufferEntry.maxTextLength + 100)
        let entry = BufferEntry(text: text, source: .share)
        #expect(entry.text.count < text.count)
        #expect(entry.text.hasSuffix("... (truncated)"))
    }

    @Test("maxTextLength is 50,000")
    func maxTextLengthValue() {
        #expect(BufferEntry.maxTextLength == 50_000)
    }
}
