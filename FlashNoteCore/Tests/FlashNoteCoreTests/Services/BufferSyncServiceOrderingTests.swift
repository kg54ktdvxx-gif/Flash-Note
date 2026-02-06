import Testing
import Foundation
@testable import FlashNoteCore

@Suite("Buffer Sync Ordering")
struct BufferSyncServiceOrderingTests {

    private func makeTempBuffer() -> (FileBasedHotCaptureBuffer, URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let file = tempDir.appendingPathComponent("test_sync_\(UUID().uuidString).jsonl")
        let buffer = FileBasedHotCaptureBuffer(fileURL: file)
        return (buffer, file)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("read-then-clear pattern preserves entries before clearing")
    func readThenClearOrdering() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        // Simulate capture: append entries
        let entry1 = BufferEntry(text: "First thought", source: .keyboard)
        let entry2 = BufferEntry(text: "Second thought", source: .siri)
        try buffer.append(entry1)
        try buffer.append(entry2)

        // Step 1: Read all entries (as BufferSyncService.flush does)
        let entries = try buffer.readAll()
        #expect(entries.count == 2)
        #expect(entries[0].text == "First thought")
        #expect(entries[1].text == "Second thought")

        // Step 2: Clear buffer (entries now only in memory)
        try buffer.clear()

        // Step 3: Verify buffer is empty
        let afterClear = try buffer.readAll()
        #expect(afterClear.isEmpty)

        // Step 4: Verify the in-memory entries are still usable for Note creation
        #expect(entries[0].id == entry1.id)
        #expect(entries[1].id == entry2.id)
        #expect(entries[0].source == .keyboard)
        #expect(entries[1].source == .siri)
    }

    @Test("entries appended during flush are not lost")
    func concurrentAppendDuringFlush() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        // Pre-flush: append initial entries
        try buffer.append(BufferEntry(text: "Before flush", source: .keyboard))

        // Simulate flush: read + clear
        let flushed = try buffer.readAll()
        #expect(flushed.count == 1)
        try buffer.clear()

        // Simulate new entry arriving after clear (as if captured during save)
        try buffer.append(BufferEntry(text: "During flush", source: .voice))

        // Next flush should see the new entry
        let nextFlush = try buffer.readAll()
        #expect(nextFlush.count == 1)
        #expect(nextFlush[0].text == "During flush")
    }

    @Test("empty buffer flush is a no-op")
    func emptyBufferFlush() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let entries = try buffer.readAll()
        #expect(entries.isEmpty)

        // Clear on empty should not throw
        try buffer.clear()

        let afterClear = try buffer.readAll()
        #expect(afterClear.isEmpty)
    }
}
