import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor @Observable
final class SettingsViewModel {
    var resurfacingEnabled: Bool {
        didSet { UserDefaults.standard.set(resurfacingEnabled, forKey: "resurfacingEnabled") }
    }
    var maxDailyNotifications: Int {
        didSet { UserDefaults.standard.set(maxDailyNotifications, forKey: "maxDailyNotifications") }
    }
    var quietHoursEnabled: Bool {
        didSet { UserDefaults.standard.set(quietHoursEnabled, forKey: "quietHoursEnabled") }
    }
    var dailyReflectionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReflectionEnabled, forKey: "dailyReflectionEnabled")
            if dailyReflectionEnabled {
                ResurfacingScheduler.scheduleDailyReflection()
            } else {
                ResurfacingScheduler.cancelDailyReflection()
            }
        }
    }
    var shakeEnabled: Bool {
        didSet { UserDefaults.standard.set(shakeEnabled, forKey: "shakeEnabled") }
    }

    var noteCount = 0
    var activeNoteCount = 0
    var archivedNoteCount = 0

    private let exportService = DefaultExportService()

    init() {
        self.resurfacingEnabled = UserDefaults.standard.object(forKey: "resurfacingEnabled") as? Bool ?? true
        self.maxDailyNotifications = UserDefaults.standard.object(forKey: "maxDailyNotifications") as? Int ?? 3
        self.quietHoursEnabled = UserDefaults.standard.object(forKey: "quietHoursEnabled") as? Bool ?? true
        self.dailyReflectionEnabled = UserDefaults.standard.object(forKey: "dailyReflectionEnabled") as? Bool ?? false
        self.shakeEnabled = UserDefaults.standard.object(forKey: "shakeEnabled") as? Bool ?? true
    }

    func loadStats(context: ModelContext) {
        do {
            let allPredicate = #Predicate<Note> { $0.statusRaw != "deleted" }
            noteCount = try context.fetchCount(FetchDescriptor<Note>(predicate: allPredicate))

            let activePredicate = #Predicate<Note> { $0.statusRaw == "active" }
            activeNoteCount = try context.fetchCount(FetchDescriptor<Note>(predicate: activePredicate))

            let archivedPredicate = #Predicate<Note> { $0.statusRaw == "archived" }
            archivedNoteCount = try context.fetchCount(FetchDescriptor<Note>(predicate: archivedPredicate))
        } catch {
            FNLog.capture.error("Failed to load stats: \(error)")
        }
    }

    func exportAll(format: ExportFormat, context: ModelContext) -> URL? {
        do {
            let predicate = #Predicate<Note> { $0.statusRaw != "deleted" }
            let descriptor = FetchDescriptor<Note>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let notes = try context.fetch(descriptor)
            return try exportService.exportToFile(notes: notes, format: format)
        } catch {
            FNLog.export.error("Bulk export failed: \(error)")
            return nil
        }
    }

    func deleteAllArchived(context: ModelContext) {
        do {
            let predicate = #Predicate<Note> { $0.statusRaw == "archived" }
            let descriptor = FetchDescriptor<Note>(predicate: predicate)
            let notes = try context.fetch(descriptor)
            for note in notes {
                note.status = .deleted
                note.updatedAt = .now
                SpotlightIndexer.remove(noteID: note.id)
                if let audioFileName = note.audioFileName {
                    AppGroupContainer.deleteAudioFile(named: audioFileName)
                }
            }
            try context.save()
            loadStats(context: context)
        } catch {
            FNLog.capture.error("Failed to delete archived: \(error)")
        }
    }

    /// Purges soft-deleted notes older than 30 days — called on app launch.
    func purgeOldDeletedNotes(context: ModelContext) {
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
