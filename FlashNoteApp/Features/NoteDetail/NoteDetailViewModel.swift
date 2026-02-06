import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor @Observable
final class NoteDetailViewModel {
    var editedText: String
    var isEditing = false
    var showExport = false
    var showDeleteConfirmation = false

    let note: Note

    init(note: Note) {
        self.note = note
        self.editedText = note.text
    }

    func saveEdit(context: ModelContext) {
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        note.text = trimmed
        note.updatedAt = .now

        do {
            try context.save()
            SpotlightIndexer.index(note: note)
            isEditing = false
        } catch {
            FNLog.capture.error("Failed to save edit: \(error)")
        }
    }

    func deleteNote(context: ModelContext) {
        note.status = .deleted
        note.updatedAt = .now
        SpotlightIndexer.remove(noteID: note.id)
        ResurfacingScheduler.cancelResurfacing(for: note.id)

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Failed to delete note: \(error)")
        }
    }

    func toggleTask(context: ModelContext) {
        if note.isTask {
            note.isTaskCompleted.toggle()
        } else {
            note.isTask = true
            note.isTaskCompleted = false
            note.status = .task
        }
        note.updatedAt = .now

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Failed to toggle task: \(error)")
        }
    }

    func cancelEdit() {
        editedText = note.text
        isEditing = false
    }
}
