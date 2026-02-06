import Testing
import Foundation
@testable import FlashNoteCore

@Suite("FileBasedHotCaptureBuffer Concurrency")
struct HotCaptureBufferConcurrencyTests {

    private func makeTempBuffer() -> (FileBasedHotCaptureBuffer, URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let file = tempDir.appendingPathComponent("test_concurrent_\(UUID().uuidString).jsonl")
        let buffer = FileBasedHotCaptureBuffer(fileURL: file)
        return (buffer, file)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("concurrent appends do not lose entries")
    func concurrentAppends() async throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        let count = 50
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<count {
                group.addTask {
                    try? buffer.append(BufferEntry(text: "Entry \(i)", source: .keyboard))
                }
            }
        }

        let entries = try buffer.readAll()
        #expect(entries.count == count)
    }

    @Test("concurrent append and readAll do not crash")
    func concurrentAppendAndRead() async throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        // Pre-populate
        for i in 0..<10 {
            try buffer.append(BufferEntry(text: "Pre \(i)", source: .keyboard))
        }

        await withTaskGroup(of: Void.self) { group in
            // Readers
            for _ in 0..<10 {
                group.addTask {
                    _ = try? buffer.readAll()
                }
            }
            // Writers
            for i in 0..<10 {
                group.addTask {
                    try? buffer.append(BufferEntry(text: "Concurrent \(i)", source: .siri))
                }
            }
        }

        let entries = try buffer.readAll()
        #expect(entries.count == 20)
    }

    @Test("concurrent append and clear do not crash")
    func concurrentAppendAndClear() async throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        // This should not crash regardless of interleaving
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    try? buffer.append(BufferEntry(text: "Entry \(i)", source: .keyboard))
                }
            }
            group.addTask {
                try? buffer.clear()
            }
        }

        // Result is non-deterministic, but no crash is the success criteria
        let entries = try buffer.readAll()
        #expect(entries.count >= 0)
    }

    @Test("readAll is consistent — returns complete entries only")
    func readAllConsistency() throws {
        let (buffer, file) = makeTempBuffer()
        defer { cleanup(file) }

        for i in 0..<100 {
            try buffer.append(BufferEntry(text: "Consistency \(i)", source: .keyboard))
        }

        let entries = try buffer.readAll()
        #expect(entries.count == 100)
        // Every entry should have non-empty text
        for entry in entries {
            #expect(!entry.text.isEmpty)
        }
    }
}
