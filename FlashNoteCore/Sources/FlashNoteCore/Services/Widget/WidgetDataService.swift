import Foundation
import SwiftData

/// Writes recent note data to shared UserDefaults so widgets can display it.
public enum WidgetDataService {
    private static let recentNotesKey = "recentNotes"
    private static let maxRecentNotes = 5

    /// Encodes recent notes into shared UserDefaults for widget consumption.
    @MainActor
    public static func updateRecentNotes(context: ModelContext) {
        let activeRaw = NoteStatus.active.rawValue
        let taskRaw = NoteStatus.task.rawValue
        let predicate = #Predicate<Note> { note in
            note.statusRaw == activeRaw || note.statusRaw == taskRaw
        }

        var descriptor = FetchDescriptor<Note>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = maxRecentNotes

        do {
            let notes = try context.fetch(descriptor)
            let items = notes.map { note in
                WidgetNoteItem(
                    id: note.id,
                    text: String(note.text.prefix(80)),
                    timeAgo: DateHelpers.shortRelativeString(from: note.createdAt)
                )
            }

            let data = try JSONEncoder().encode(items)
            AppGroupContainer.sharedDefaults.set(data, forKey: recentNotesKey)
        } catch {
            FNLog.widget.error("Failed to update widget data: \(error)")
        }
    }
}

/// Matches the format expected by RecentNotesWidget.
private struct WidgetNoteItem: Codable {
    let id: UUID
    let text: String
    let timeAgo: String
}
