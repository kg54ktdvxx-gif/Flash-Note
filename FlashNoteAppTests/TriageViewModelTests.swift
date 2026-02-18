import Foundation
import Testing
import SwiftData
@testable import FlashNote
import FlashNoteCore

@Suite("TriageViewModel")
@MainActor
struct TriageViewModelTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: - Computed properties

    @Test("currentNote is nil when triageNotes is empty")
    func currentNoteNilWhenEmpty() {
        let vm = TriageViewModel()
        #expect(vm.currentNote == nil)
    }

    @Test("progress is 1.0 when empty")
    func progressEmptyIs1() {
        let vm = TriageViewModel()
        #expect(vm.progress == 1.0)
    }

    @Test("remaining is 0 when empty")
    func remainingEmpty() {
        let vm = TriageViewModel()
        #expect(vm.remaining == 0)
    }

    @Test("isComplete is true when empty")
    func isCompleteWhenEmpty() {
        let vm = TriageViewModel()
        #expect(vm.isComplete)
    }

    // MARK: - loadNotes

    @Test("loadNotes fetches active untriaged notes")
    func loadNotesActiveUntriaged() throws {
        let context = try makeContext()

        let active = Note(text: "Active untriaged")
        context.insert(active)

        let triaged = Note(text: "Already triaged")
        triaged.isTriaged = true
        context.insert(triaged)

        let archived = Note(text: "Archived")
        archived.status = .archived
        context.insert(archived)

        try context.save()

        let vm = TriageViewModel()
        vm.loadNotes(context: context)

        #expect(vm.triageNotes.count == 1)
        #expect(vm.triageNotes[0].text == "Active untriaged")
    }

    @Test("loadNotes excludes deleted notes")
    func loadNotesExcludesDeleted() throws {
        let context = try makeContext()

        let deleted = Note(text: "Deleted")
        deleted.status = .deleted
        context.insert(deleted)

        try context.save()

        let vm = TriageViewModel()
        vm.loadNotes(context: context)
        #expect(vm.triageNotes.isEmpty)
    }

    // MARK: - performAction

    @Test("keep action sets isTriaged true and advances index")
    func keepAction() throws {
        let context = try makeContext()
        let note = Note(text: "Keep me")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.keep, context: context)

        #expect(note.isTriaged)
        #expect(note.status == .active)
        #expect(vm.currentIndex == 1)
    }

    @Test("archive action sets status archived and isTriaged")
    func archiveAction() throws {
        let context = try makeContext()
        let note = Note(text: "Archive me")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.archive, context: context)

        #expect(note.status == .archived)
        #expect(note.isTriaged)
        #expect(vm.currentIndex == 1)
    }

    @Test("task action sets isTask, status .task, and isTriaged")
    func taskAction() throws {
        let context = try makeContext()
        let note = Note(text: "Do this")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.task, context: context)

        #expect(note.isTask)
        #expect(note.status == .task)
        #expect(note.isTriaged)
    }

    @Test("performAction is no-op when currentNote is nil")
    func performActionNoOpWhenNil() throws {
        let context = try makeContext()
        let vm = TriageViewModel()
        vm.performAction(.keep, context: context) // should not crash
        #expect(vm.currentIndex == 0)
        #expect(vm.undoStack.isEmpty)
    }

    @Test("remaining decrements with each action")
    func remainingDecrements() throws {
        let context = try makeContext()
        let n1 = Note(text: "One")
        let n2 = Note(text: "Two")
        context.insert(n1)
        context.insert(n2)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [n1, n2]
        #expect(vm.remaining == 2)

        vm.performAction(.keep, context: context)
        #expect(vm.remaining == 1)

        vm.performAction(.keep, context: context)
        #expect(vm.remaining == 0)
        #expect(vm.isComplete)
    }

    @Test("progress updates correctly through triage queue")
    func progressUpdates() throws {
        let context = try makeContext()
        let n1 = Note(text: "A")
        let n2 = Note(text: "B")
        context.insert(n1)
        context.insert(n2)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [n1, n2]
        #expect(vm.progress == 0.0)

        vm.performAction(.keep, context: context)
        #expect(vm.progress == 0.5)

        vm.performAction(.keep, context: context)
        #expect(vm.progress == 1.0)
    }

    // MARK: - Undo

    @Test("undo on empty stack is a no-op")
    func undoEmptyStack() throws {
        let context = try makeContext()
        let vm = TriageViewModel()
        vm.undo(context: context) // should not crash
        #expect(vm.currentIndex == 0)
    }

    @Test("undo after keep restores isTriaged to false")
    func undoKeep() throws {
        let context = try makeContext()
        let note = Note(text: "Keep then undo")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.keep, context: context)
        #expect(note.isTriaged)
        #expect(vm.currentIndex == 1)

        vm.undo(context: context)
        #expect(!note.isTriaged)
        #expect(vm.currentIndex == 0)
    }

    @Test("undo after archive restores status and isTriaged")
    func undoArchive() throws {
        let context = try makeContext()
        let note = Note(text: "Archive then undo")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.archive, context: context)
        #expect(note.status == .archived)

        vm.undo(context: context)
        #expect(note.status == .active)
        #expect(!note.isTriaged)
    }

    @Test("undo after task restores isTask and status")
    func undoTask() throws {
        let context = try makeContext()
        let note = Note(text: "Task then undo")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.task, context: context)
        #expect(note.isTask)

        vm.undo(context: context)
        #expect(!note.isTask)
        #expect(note.status == .active)
    }

    @Test("currentIndex does not go below 0 on undo")
    func undoDoesNotGoBelowZero() throws {
        let context = try makeContext()
        let note = Note(text: "Note")
        context.insert(note)
        try context.save()

        let vm = TriageViewModel()
        vm.triageNotes = [note]
        vm.performAction(.keep, context: context)

        vm.undo(context: context)
        #expect(vm.currentIndex == 0)

        // Undo again — stack is now empty, should stay at 0
        vm.undo(context: context)
        #expect(vm.currentIndex == 0)
    }
}
