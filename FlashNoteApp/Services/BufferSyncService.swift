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

        // Save to SwiftData FIRST. If save fails, rollback the inserts and leave
        // the buffer intact so entries survive for the next flush attempt.
        // Lost thoughts are unrecoverable; duplicate entries can be cleaned up.
        do {
            try context.save()
        } catch {
            FNLog.sync.error("Failed to save flushed entries, rolling back — will retry next launch: \(error)")
            context.rollback()
            return
        }

        // Save succeeded — now clear the buffer. If clear fails, next flush may
        // re-insert duplicates, but that's far better than losing data.
        do {
            try buffer.clear()
            FNLog.sync.info("Successfully flushed \(entries.count) entries")
        } catch {
            FNLog.sync.error("Buffer clear failed after successful save — duplicates possible on next flush: \(error)")
        }
    }
}
