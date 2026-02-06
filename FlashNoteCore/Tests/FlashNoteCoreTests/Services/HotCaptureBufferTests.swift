import Testing
import Foundation
@testable import FlashNoteCore

@Suite("FileBasedHotCaptureBuffer")
struct HotCaptureBufferTests {

    private func makeTempBuffer() -> (FileBasedHotCaptureBuffer, URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let file = tempDir.appendingPathComponent("test_buffer_\(UUID().uuidString).jsonl")
        let buffer = FileBasedHotCaptureBuffer(fileURL: file)
        return (buffer, file)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Basic operations

    @Test("append then readAll returns the entry")
    func appendAndRead() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let entry = BufferEntry(text: "Hello", source: .keyboard)
        try buffer.append(entry)

        let entries = try buffer.readAll()
        #expect(entries.count == 1)
        #expect(entries[0].text == "Hello")
        #expect(entries[0].source == .keyboard)
        #expect(entries[0].id == entry.id)
    }

    @Test("multiple appends accumulate")
    func multipleAppends() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        try buffer.append(BufferEntry(text: "One", source: .keyboard))
        try buffer.append(BufferEntry(text: "Two", source: .siri))
        try buffer.append(BufferEntry(text: "Three", source: .share))

        let entries = try buffer.readAll()
        #expect(entries.count == 3)
        #expect(entries[0].text == "One")
        #expect(entries[1].text == "Two")
        #expect(entries[2].text == "Three")
    }

    @Test("clear removes all entries")
    func clearRemovesAll() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        try buffer.append(BufferEntry(text: "A", source: .keyboard))
        try buffer.append(BufferEntry(text: "B", source: .keyboard))
        try buffer.clear()

        let entries = try buffer.readAll()
        #expect(entries.count == 0)
    }

    @Test("readAll on empty/nonexistent file returns empty array")
    func readEmptyFile() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let entries = try buffer.readAll()
        #expect(entries.isEmpty)
    }

    @Test("clear on nonexistent file does not throw")
    func clearNonexistent() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        // Should not throw even though file doesn't exist
        try buffer.clear()
    }

    // MARK: - Data integrity

    @Test("entries preserve all fields through JSONL round-trip")
    func fieldPreservation() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let entry = BufferEntry(text: "Voice note", source: .voice, audioFileName: "recording.m4a")
        try buffer.append(entry)

        let entries = try buffer.readAll()
        #expect(entries.count == 1)
        #expect(entries[0].id == entry.id)
        #expect(entries[0].text == "Voice note")
        #expect(entries[0].sourceRaw == "voice")
        #expect(entries[0].audioFileName == "recording.m4a")
    }

    @Test("entries with special characters survive round-trip")
    func specialCharacters() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let entry = BufferEntry(text: "Line 1\nLine 2\ttab \"quotes\" 🎯", source: .keyboard)
        try buffer.append(entry)

        let entries = try buffer.readAll()
        #expect(entries.count == 1)
        #expect(entries[0].text == "Line 1\nLine 2\ttab \"quotes\" 🎯")
    }

    @Test("corrupt line is skipped, valid lines still read")
    func corruptLineSkipped() throws {
        let (_, file) = makeTempBuffer()
        defer { cleanup(file) }

        // Write a valid entry, then garbage, then another valid entry
        let buffer = FileBasedHotCaptureBuffer(fileURL: file)
        let entry1 = BufferEntry(text: "Valid 1", source: .keyboard)
        try buffer.append(entry1)

        // Manually append corrupt data
        let handle = try FileHandle(forWritingTo: file)
        handle.seekToEndOfFile()
        handle.write("not valid json\n".data(using: .utf8)!)
        try handle.close()

        let entry2 = BufferEntry(text: "Valid 2", source: .siri)
        try buffer.append(entry2)

        let entries = try buffer.readAll()
        // compactMap skips the corrupt line
        #expect(entries.count == 2)
        #expect(entries[0].text == "Valid 1")
        #expect(entries[1].text == "Valid 2")
    }

    // MARK: - Append after clear

    @Test("can append after clear")
    func appendAfterClear() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        try buffer.append(BufferEntry(text: "Before", source: .keyboard))
        try buffer.clear()
        try buffer.append(BufferEntry(text: "After", source: .keyboard))

        let entries = try buffer.readAll()
        #expect(entries.count == 1)
        #expect(entries[0].text == "After")
    }
}
