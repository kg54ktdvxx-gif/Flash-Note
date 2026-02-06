import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("LocalNoteSearchService")
struct NoteSearchServiceTests {

    private let service = LocalNoteSearchService()

    private func makeContext(with texts: [String]) throws -> ModelContext {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        for text in texts {
            let note = Note(text: text)
            context.insert(note)
        }
        try context.save()
        return context
    }

    @MainActor
    @Test("search finds matching notes")
    func searchFindsMatch() throws {
        let context = try makeContext(with: ["Buy groceries", "Call dentist", "Buy birthday gift"])
        let results = try service.search(query: "buy", in: context)
        #expect(results.count == 2)
    }

    @MainActor
    @Test("search is case insensitive")
    func searchCaseInsensitive() throws {
        let context = try makeContext(with: ["Hello World"])
        let results = try service.search(query: "HELLO", in: context)
        #expect(results.count == 1)
    }

    @MainActor
    @Test("search returns empty for no match")
    func searchNoMatch() throws {
        let context = try makeContext(with: ["Buy groceries"])
        let results = try service.search(query: "dentist", in: context)
        #expect(results.isEmpty)
    }

    @MainActor
    @Test("search with empty query returns empty array")
    func searchEmptyQuery() throws {
        let context = try makeContext(with: ["Buy groceries"])
        let results = try service.search(query: "", in: context)
        #expect(results.isEmpty)
    }

    @MainActor
    @Test("search with whitespace-only query returns empty array")
    func searchWhitespaceQuery() throws {
        let context = try makeContext(with: ["Buy groceries"])
        let results = try service.search(query: "   ", in: context)
        #expect(results.isEmpty)
    }

    @Test("NoteStatus.deleted.rawValue matches expected string")
    func deletedRawValue() {
        #expect(NoteStatus.deleted.rawValue == "deleted")
    }

    @MainActor
    @Test("search excludes deleted notes")
    func searchExcludesDeleted() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let note1 = Note(text: "Active groceries")
        let note2 = Note(text: "Deleted groceries")
        note2.status = .deleted
        context.insert(note1)
        context.insert(note2)
        try context.save()

        let results = try service.search(query: "groceries", in: context)
        #expect(results.count == 1)
        #expect(results[0].text == "Active groceries")
    }
}
