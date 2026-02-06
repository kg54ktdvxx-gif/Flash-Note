import SwiftUI
import SwiftData
import FlashNoteCore

enum TriageAction: Sendable {
    case keep
    case archive
    case task
}

struct TriageUndoEntry: Sendable {
    let noteID: UUID
    let action: TriageAction
    let previousStatus: NoteStatus
    let previousIsTriaged: Bool
    let previousIsTask: Bool
}

@MainActor @Observable
final class TriageViewModel {
    var currentIndex = 0
    var undoStack: [TriageUndoEntry] = []

    var triageNotes: [Note] = []

    var currentNote: Note? {
        guard currentIndex < triageNotes.count else { return nil }
        return triageNotes[currentIndex]
    }

    var progress: Double {
        guard !triageNotes.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(triageNotes.count)
    }

    var remaining: Int {
        max(triageNotes.count - currentIndex, 0)
    }

    var isComplete: Bool {
        currentIndex >= triageNotes.count
    }

    func loadNotes(context: ModelContext) {
        let predicate = #Predicate<Note> { note in
            note.statusRaw == "active" && !note.isTriaged
        }

        var descriptor = FetchDescriptor<Note>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 50

        do {
            triageNotes = try context.fetch(descriptor)
        } catch {
            FNLog.capture.error("Failed to load triage notes: \(error)")
        }
    }

    func performAction(_ action: TriageAction, context: ModelContext) {
        guard let note = currentNote else { return }

        let undoEntry = TriageUndoEntry(
            noteID: note.id,
            action: action,
            previousStatus: note.status,
            previousIsTriaged: note.isTriaged,
            previousIsTask: note.isTask
        )
        undoStack.append(undoEntry)

        switch action {
        case .keep:
            note.isTriaged = true
        case .archive:
            note.status = .archived
            note.isTriaged = true
            ResurfacingScheduler.cancelResurfacing(for: note.id)
        case .task:
            note.isTask = true
            note.status = .task
            note.isTriaged = true
        }

        note.updatedAt = .now

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Triage action failed: \(error)")
        }

        currentIndex += 1
    }

    func undo(context: ModelContext) {
        guard let entry = undoStack.popLast() else { return }
        guard let note = triageNotes.first(where: { $0.id == entry.noteID }) else { return }

        note.status = entry.previousStatus
        note.isTriaged = entry.previousIsTriaged
        note.isTask = entry.previousIsTask
        note.updatedAt = .now

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Undo failed: \(error)")
        }

        currentIndex = max(currentIndex - 1, 0)
    }
}
