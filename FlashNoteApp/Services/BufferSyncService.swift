import SwiftData
import FlashNoteCore

enum BufferSyncService {
    @MainActor
    static func flush(to context: ModelContext) {
        let buffer = FileBasedHotCaptureBuffer()
        let entries: [BufferEntry]
        do {
            entries = try buffer.readAll()
        } catch {
            FNLog.sync.error("Failed to read buffer: \(error)")
            return
        }

        guard !entries.isEmpty else { return }

        FNLog.sync.info("Flushing \(entries.count) buffered entries to SwiftData")

        for entry in entries {
            let note = Note(
                text: entry.text,
                source: entry.source,
                audioFileName: entry.audioFileName
            )
            note.createdAt = entry.capturedAt
            context.insert(note)
        }

        do {
            try context.save()
            try buffer.clear()
            FNLog.sync.info("Successfully flushed \(entries.count) entries")
        } catch {
            FNLog.sync.error("Failed to save flushed entries: \(error)")
        }
    }
}
