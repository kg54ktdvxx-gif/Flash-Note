import Foundation
import Testing
import SwiftData
@testable import FlashNote
import FlashNoteCore

@Suite("CaptureViewModel")
@MainActor
struct CaptureViewModelTests {

    private static let draftKey = "capture_draft"

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func cleanUpDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    // MARK: - canSave

    @Test("canSave is false for empty text")
    func canSaveEmpty() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = ""
        #expect(!vm.canSave)
    }

    @Test("canSave is false for whitespace-only text")
    func canSaveWhitespace() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = "  \n\t  "
        #expect(!vm.canSave)
    }

    @Test("canSave is true for non-empty text")
    func canSaveNonEmpty() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = "Hello"
        #expect(vm.canSave)
    }

    // MARK: - Draft persistence

    @Test("saveDraft writes to UserDefaults")
    func saveDraftWrites() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = "Draft text"
        vm.saveDraft()

        let stored = UserDefaults.standard.string(forKey: Self.draftKey)
        #expect(stored == "Draft text")
        cleanUpDraft()
    }

    @Test("saveDraft removes key when text is whitespace-only")
    func saveDraftClearsEmpty() {
        UserDefaults.standard.set("Old draft", forKey: Self.draftKey)
        let vm = CaptureViewModel()
        vm.text = "   "
        vm.saveDraft()

        let stored = UserDefaults.standard.string(forKey: Self.draftKey)
        #expect(stored == nil)
    }

    @Test("init restores draft from UserDefaults")
    func initRestoresDraft() {
        UserDefaults.standard.set("Restored draft", forKey: Self.draftKey)
        let vm = CaptureViewModel()
        #expect(vm.text == "Restored draft")
        cleanUpDraft()
    }

    @Test("init with empty draft starts with empty text")
    func initEmptyDraft() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        #expect(vm.text.isEmpty)
    }

    // MARK: - save

    @Test("save creates a Note with keyboard source")
    func saveCreatesNote() throws {
        cleanUpDraft()
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.text = "New note"
        vm.save(context: context)

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes.count == 1)
        #expect(notes[0].text == "New note")
        #expect(notes[0].source == .keyboard)
    }

    @Test("save clears text and shows confirmation")
    func saveClearsAndConfirms() throws {
        cleanUpDraft()
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.text = "Note to save"
        vm.save(context: context)

        #expect(vm.text.isEmpty)
        #expect(vm.showSaveConfirmation)
    }

    @Test("save with whitespace-only text is a no-op")
    func saveWhitespaceNoOp() throws {
        cleanUpDraft()
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.text = "  \n  "
        vm.save(context: context)

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes.isEmpty)
        #expect(!vm.showSaveConfirmation)
    }

    @Test("save trims whitespace from text")
    func saveTrims() throws {
        cleanUpDraft()
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.text = "  Padded note  \n"
        vm.save(context: context)

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes[0].text == "Padded note")
    }

    @Test("save clears draft from UserDefaults")
    func saveClearsDraft() throws {
        cleanUpDraft()
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.text = "Will be saved"
        vm.saveDraft()
        #expect(UserDefaults.standard.string(forKey: Self.draftKey) != nil)

        vm.save(context: context)
        #expect(UserDefaults.standard.string(forKey: Self.draftKey) == nil)
        cleanUpDraft()
    }

    // MARK: - saveVoiceNote

    @Test("saveVoiceNote creates Note with voice source and audio metadata")
    func saveVoiceNote() throws {
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.saveVoiceNote(
            text: "Transcribed text",
            audioFileName: "test.m4a",
            audioDuration: 12.5,
            confidence: 0.95,
            context: context
        )

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes.count == 1)
        #expect(notes[0].source == .voice)
        #expect(notes[0].audioFileName == "test.m4a")
        #expect(notes[0].audioDuration == 12.5)
        #expect(notes[0].transcriptionConfidence == 0.95)
    }

    @Test("saveVoiceNote with empty text is a no-op")
    func saveVoiceNoteEmptyNoOp() throws {
        let context = try makeContext()
        let vm = CaptureViewModel()
        vm.saveVoiceNote(
            text: "  ",
            audioFileName: "test.m4a",
            audioDuration: 5.0,
            confidence: nil,
            context: context
        )

        let descriptor = FetchDescriptor<Note>()
        let notes = try context.fetch(descriptor)
        #expect(notes.isEmpty)
    }

    // MARK: - handlePrefill

    @Test("handlePrefill sets text")
    func handlePrefill() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.handlePrefill("Prefilled text")
        #expect(vm.text == "Prefilled text")
    }

    @Test("handlePrefill with nil is a no-op")
    func handlePrefillNil() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = "Existing"
        vm.handlePrefill(nil)
        #expect(vm.text == "Existing")
    }

    @Test("handlePrefill with empty string is a no-op")
    func handlePrefillEmpty() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.text = "Existing"
        vm.handlePrefill("")
        #expect(vm.text == "Existing")
    }

    // MARK: - dismissMerge

    @Test("dismissMerge clears showMergePrompt state")
    func dismissMerge() {
        cleanUpDraft()
        let vm = CaptureViewModel()
        vm.dismissMerge() // should not crash
        #expect(!vm.showMergePrompt)
    }
}
