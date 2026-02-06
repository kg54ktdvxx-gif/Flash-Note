import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("Note")
struct NoteTests {

    // MARK: - Init defaults

    @Test("init sets expected defaults")
    func initDefaults() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "Hello world")
        context.insert(note)

        #expect(note.text == "Hello world")
        #expect(note.status == .active)
        #expect(note.source == .keyboard)
        #expect(note.audioFileName == nil)
        #expect(note.audioDuration == nil)
        #expect(note.transcriptionConfidence == nil)
        #expect(note.resurfaceCount == 0)
        #expect(note.isTriaged == false)
        #expect(note.isTask == false)
        #expect(note.isTaskCompleted == false)
    }

    @Test("init with voice source")
    func initWithVoice() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(
            text: "Voice note",
            source: .voice,
            audioFileName: "test.m4a",
            audioDuration: 5.0,
            transcriptionConfidence: 0.95
        )
        context.insert(note)

        #expect(note.source == .voice)
        #expect(note.sourceRaw == "voice")
        #expect(note.audioFileName == "test.m4a")
        #expect(note.audioDuration == 5.0)
        #expect(note.transcriptionConfidence == 0.95)
    }

    // MARK: - Transient computed properties

    @Test("status transient getter/setter round-trips through statusRaw")
    func statusTransient() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "test")
        context.insert(note)

        #expect(note.status == .active)
        #expect(note.statusRaw == "active")

        note.status = .archived
        #expect(note.statusRaw == "archived")
        #expect(note.status == .archived)

        note.status = .task
        #expect(note.statusRaw == "task")

        note.status = .deleted
        #expect(note.statusRaw == "deleted")
    }

    @Test("source transient getter/setter round-trips through sourceRaw")
    func sourceTransient() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "test")
        context.insert(note)

        note.source = .siri
        #expect(note.sourceRaw == "siri")
        #expect(note.source == .siri)
    }

    @Test("invalid statusRaw falls back to .active")
    func invalidStatusFallback() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "test")
        context.insert(note)
        note.statusRaw = "bogus"
        #expect(note.status == .active)
    }

    @Test("invalid sourceRaw falls back to .keyboard")
    func invalidSourceFallback() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "test")
        context.insert(note)
        note.sourceRaw = "bogus"
        #expect(note.source == .keyboard)
    }

    // MARK: - previewText

    @Test("previewText returns full text when <= 100 chars")
    func previewTextShort() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "Short note")
        context.insert(note)
        #expect(note.previewText == "Short note")
    }

    @Test("previewText returns exactly 100 chars when text is 100 chars")
    func previewTextExact100() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let text = String(repeating: "a", count: 100)
        let note = Note(text: text)
        context.insert(note)
        #expect(note.previewText == text)
        #expect(note.previewText.count == 100)
    }

    @Test("previewText truncates at 100 chars with ellipsis when > 100")
    func previewTextTruncated() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let text = String(repeating: "b", count: 200)
        let note = Note(text: text)
        context.insert(note)
        #expect(note.previewText.count == 103) // 100 chars + "..."
        #expect(note.previewText.hasSuffix("..."))
    }

    @Test("previewText handles empty text")
    func previewTextEmpty() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "")
        context.insert(note)
        #expect(note.previewText == "")
    }

    // MARK: - audioURL

    @Test("audioURL is nil when audioFileName is nil")
    func audioURLNil() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "no audio")
        context.insert(note)
        #expect(note.audioURL == nil)
    }

    @Test("audioURL is constructed when audioFileName is present")
    func audioURLPresent() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)

        let note = Note(text: "has audio", audioFileName: "test.m4a")
        context.insert(note)
        #expect(note.audioURL != nil)
        #expect(note.audioURL!.lastPathComponent == "test.m4a")
    }
}
