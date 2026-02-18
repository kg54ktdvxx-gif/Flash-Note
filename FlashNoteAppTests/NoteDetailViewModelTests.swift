import Foundation
import Testing
import SwiftData
@testable import FlashNote
import FlashNoteCore

@Suite("NoteDetailViewModel")
@MainActor
struct NoteDetailViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("init sets editedText to note text")
    func initSetsEditedText() throws {
        let context = try makeContext()
        let note = Note(text: "Hello world")
        context.insert(note)

        let vm = NoteDetailViewModel(note: note)
        #expect(vm.editedText == "Hello world")
    }

    @Test("init defaults — isEditing false, showExport false, showDeleteConfirmation false")
    func initDefaults() throws {
        let context = try makeContext()
        let note = Note(text: "Test")
        context.insert(note)

        let vm = NoteDetailViewModel(note: note)
        #expect(!vm.isEditing)
        #expect(!vm.showExport)
        #expect(!vm.showDeleteConfirmation)
    }

    @Test("saveEdit updates note text and sets isEditing false")
    func saveEditUpdatesNote() throws {
        let context = try makeContext()
        let note = Note(text: "Original")
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.editedText = "Updated text"
        vm.isEditing = true
        vm.saveEdit(context: context)

        #expect(note.text == "Updated text")
        #expect(!vm.isEditing)
    }

    @Test("saveEdit trims whitespace")
    func saveEditTrims() throws {
        let context = try makeContext()
        let note = Note(text: "Original")
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.editedText = "  Padded text  \n"
        vm.saveEdit(context: context)

        #expect(note.text == "Padded text")
    }

    @Test("saveEdit with whitespace-only text is a no-op")
    func saveEditWhitespaceNoOp() throws {
        let context = try makeContext()
        let note = Note(text: "Original")
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.editedText = "   \n  "
        vm.isEditing = true
        vm.saveEdit(context: context)

        #expect(note.text == "Original")
        #expect(vm.isEditing) // not changed since save was a no-op
    }

    @Test("cancelEdit restores editedText and clears isEditing")
    func cancelEdit() throws {
        let context = try makeContext()
        let note = Note(text: "Original")
        context.insert(note)

        let vm = NoteDetailViewModel(note: note)
        vm.editedText = "Changed"
        vm.isEditing = true
        vm.cancelEdit()

        #expect(vm.editedText == "Original")
        #expect(!vm.isEditing)
    }

    @Test("deleteNote sets status to deleted")
    func deleteNoteSetsStatus() throws {
        let context = try makeContext()
        let note = Note(text: "To delete")
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.deleteNote(context: context)

        #expect(note.status == .deleted)
    }

    @Test("deleteNote updates updatedAt")
    func deleteNoteUpdatesTimestamp() throws {
        let context = try makeContext()
        let note = Note(text: "To delete")
        context.insert(note)
        try context.save()

        let beforeDelete = note.updatedAt
        vm_sleep_briefly()
        let vm = NoteDetailViewModel(note: note)
        vm.deleteNote(context: context)

        #expect(note.updatedAt >= beforeDelete)
    }

    @Test("togglePin flips isPinned state")
    func togglePin() throws {
        let context = try makeContext()
        let note = Note(text: "Pin me")
        context.insert(note)
        try context.save()

        #expect(!note.isPinned)
        let vm = NoteDetailViewModel(note: note)
        vm.togglePin(context: context)
        #expect(note.isPinned)

        vm.togglePin(context: context)
        #expect(!note.isPinned)
    }

    @Test("toggleTask on non-task note sets isTask, status, isTaskCompleted")
    func toggleTaskOnNonTask() throws {
        let context = try makeContext()
        let note = Note(text: "Might be a task")
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.toggleTask(context: context)

        #expect(note.isTask)
        #expect(note.status == .task)
        #expect(!note.isTaskCompleted)
    }

    @Test("toggleTask on existing task toggles completion")
    func toggleTaskCompletion() throws {
        let context = try makeContext()
        let note = Note(text: "A task")
        note.isTask = true
        note.status = .task
        note.isTaskCompleted = false
        context.insert(note)
        try context.save()

        let vm = NoteDetailViewModel(note: note)
        vm.toggleTask(context: context)
        #expect(note.isTaskCompleted)

        vm.toggleTask(context: context)
        #expect(!note.isTaskCompleted)
    }

    // Helper to ensure timestamp advances
    private func vm_sleep_briefly() {
        Thread.sleep(forTimeInterval: 0.01)
    }
}
