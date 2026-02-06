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

        // Clear the file buffer FIRST to prevent double-flush if clear() fails.
        // If the clear succeeds but save() fails, entries are lost — but that's
        // preferable to duplicating entries on every foreground launch.
        do {
            try buffer.clear()
        } catch {
            FNLog.sync.error("Failed to clear buffer, aborting flush to avoid duplicates: \(error)")
            return
        }

        do {
            try context.save()
            FNLog.sync.info("Successfully flushed \(entries.count) entries")
        } catch {
            // Buffer is already cleared; entries are in the context but unsaved.
            // SwiftData will retry on next save() call.
            FNLog.sync.error("Failed to save flushed entries (buffer already cleared): \(error)")
        }
    }
}
