import SwiftData
import WidgetKit
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

        // Read previously flushed IDs to avoid duplicates after crash
        let flushedIDs = readFlushedIDs()
        let newEntries = entries.filter { !flushedIDs.contains($0.id) }

        guard !newEntries.isEmpty else {
            // All entries already flushed — just clean up
            clearBufferAndFlushedIDs(buffer: buffer)
            return
        }

        FNLog.sync.info("Flushing \(newEntries.count) buffered entries to SwiftData (skipped \(entries.count - newEntries.count) already-flushed)")

        for entry in newEntries {
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
        do {
            try context.save()
        } catch {
            FNLog.sync.error("Failed to save flushed entries, rolling back — will retry next launch: \(error)")
            context.rollback()
            return
        }

        // Save succeeded — record flushed IDs before clearing buffer.
        // If the app crashes here, next flush will skip these IDs.
        let allFlushedIDs = flushedIDs.union(newEntries.map(\.id))
        writeFlushedIDs(allFlushedIDs)

        // Update widget data with newly flushed notes
        WidgetDataService.updateRecentNotes(context: context)
        WidgetCenter.shared.reloadAllTimelines()

        // Now clear the buffer. If clear fails, the flushed-IDs file protects
        // against duplicates on next flush.
        clearBufferAndFlushedIDs(buffer: buffer)
    }

    // MARK: - Flushed ID Tracking

    private static func readFlushedIDs() -> Set<UUID> {
        let url = AppGroupContainer.flushedEntryIDsFileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let ids = try JSONDecoder().decode([UUID].self, from: data)
            return Set(ids)
        } catch {
            FNLog.sync.warning("Failed to read flushed IDs, treating as empty: \(error)")
            return []
        }
    }

    private static func writeFlushedIDs(_ ids: Set<UUID>) {
        let url = AppGroupContainer.flushedEntryIDsFileURL
        do {
            let data = try JSONEncoder().encode(Array(ids))
            try data.write(to: url, options: .atomic)
        } catch {
            FNLog.sync.error("Failed to write flushed IDs: \(error)")
        }
    }

    private static func clearBufferAndFlushedIDs(buffer: FileBasedHotCaptureBuffer) {
        do {
            try buffer.clear()
            // Buffer cleared — flushed IDs file no longer needed
            let idsURL = AppGroupContainer.flushedEntryIDsFileURL
            if FileManager.default.fileExists(atPath: idsURL.path) {
                try FileManager.default.removeItem(at: idsURL)
            }
            FNLog.sync.info("Buffer and flushed IDs cleared")
        } catch {
            FNLog.sync.error("Buffer clear failed after successful save — flushed IDs file will prevent duplicates: \(error)")
        }
    }
}
