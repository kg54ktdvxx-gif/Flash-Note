import Foundation
import SwiftData
import FlashNoteCore

/// Lightweight maintenance operations called on app launch.
/// I5 fix: Extracted from SettingsViewModel to avoid allocating a full @Observable
/// ViewModel on every ContentView.onAppear.
enum NoteMaintenance {
    /// Purges soft-deleted notes older than 30 days.
    @MainActor
    static func purgeOldDeletedNotes(context: ModelContext) {
        let deletedRaw = NoteStatus.deleted.rawValue
        let cutoff = Date.now.addingTimeInterval(-30 * 86400)
        let predicate = #Predicate<Note> { note in
            note.statusRaw == deletedRaw && note.updatedAt < cutoff
        }

        do {
            let descriptor = FetchDescriptor<Note>(predicate: predicate)
            let staleNotes = try context.fetch(descriptor)
            guard !staleNotes.isEmpty else { return }

            for note in staleNotes {
                if let audioFileName = note.audioFileName {
                    AppGroupContainer.deleteAudioFile(named: audioFileName)
                }
                context.delete(note)
            }
            try context.save()
            FNLog.capture.info("Purged \(staleNotes.count) deleted notes older than 30 days")
        } catch {
            FNLog.capture.error("Failed to purge old deleted notes: \(error)")
        }
    }
}
