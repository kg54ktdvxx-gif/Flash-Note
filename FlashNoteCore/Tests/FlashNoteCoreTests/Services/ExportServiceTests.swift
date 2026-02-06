import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("DefaultExportService")
struct ExportServiceTests {

    private let service = DefaultExportService()

    private func makeNotes(texts: [String]) throws -> [Note] {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        return texts.map { text in
            let note = Note(text: text)
            context.insert(note)
            return note
        }
    }

    // MARK: - Markdown

    @Test("markdown export starts with header")
    func markdownHeader() throws {
        let notes = try makeNotes(texts: ["Hello"])
        let result = service.export(notes: notes, format: .markdown)
        #expect(result.hasPrefix("# FlashNote Export"))
    }

    @Test("markdown export contains note text")
    func markdownContainsText() throws {
        let notes = try makeNotes(texts: ["Buy groceries", "Call dentist"])
        let result = service.export(notes: notes, format: .markdown)
        #expect(result.contains("Buy groceries"))
        #expect(result.contains("Call dentist"))
    }

    @Test("markdown export contains separators between notes")
    func markdownSeparators() throws {
        let notes = try makeNotes(texts: ["A", "B"])
        let result = service.export(notes: notes, format: .markdown)
        #expect(result.contains("---"))
    }

    @Test("markdown export with empty array returns just header")
    func markdownEmpty() throws {
        let result = service.export(notes: [], format: .markdown)
        #expect(result.hasPrefix("# FlashNote Export"))
        #expect(!result.contains("---"))
    }

    // MARK: - Plain text

    @Test("plain text export contains note text")
    func plainTextContainsText() throws {
        let notes = try makeNotes(texts: ["Test note"])
        let result = service.export(notes: notes, format: .plainText)
        #expect(result.contains("Test note"))
    }

    @Test("plain text export contains timestamp brackets")
    func plainTextTimestamps() throws {
        let notes = try makeNotes(texts: ["Test"])
        let result = service.export(notes: notes, format: .plainText)
        #expect(result.contains("["))
        #expect(result.contains("]"))
    }

    @Test("plain text export empty array returns empty string")
    func plainTextEmpty() throws {
        let result = service.export(notes: [], format: .plainText)
        #expect(result == "")
    }

    // MARK: - JSON

    @Test("JSON export produces valid JSON")
    func jsonValid() throws {
        let notes = try makeNotes(texts: ["Hello world"])
        let result = service.export(notes: notes, format: .json)

        let data = result.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data)
        let array = parsed as? [[String: Any]]
        #expect(array != nil)
        #expect(array?.count == 1)
    }

    @Test("JSON export contains expected fields")
    func jsonFields() throws {
        let notes = try makeNotes(texts: ["Test"])
        let result = service.export(notes: notes, format: .json)

        #expect(result.contains("\"text\""))
        #expect(result.contains("\"createdAt\""))
        #expect(result.contains("\"source\""))
        #expect(result.contains("\"status\""))
        #expect(result.contains("Test"))
    }

    @Test("JSON export empty array returns []")
    func jsonEmpty() throws {
        let result = service.export(notes: [], format: .json)
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(trimmed == "[\n\n]")
    }

    @Test("JSON export multiple notes produces correct count")
    func jsonMultiple() throws {
        let notes = try makeNotes(texts: ["A", "B", "C"])
        let result = service.export(notes: notes, format: .json)

        let data = result.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.count == 3)
    }

    @Test("JSON export preserves source raw value")
    func jsonSourceValue() throws {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let note = Note(text: "Voice note", source: .voice)
        context.insert(note)

        let result = service.export(notes: [note], format: .json)
        #expect(result.contains("\"voice\""))
    }

    // MARK: - ExportFormat

    @Test("ExportFormat file extensions are correct")
    func fileExtensions() {
        #expect(ExportFormat.markdown.fileExtension == "md")
        #expect(ExportFormat.plainText.fileExtension == "txt")
        #expect(ExportFormat.json.fileExtension == "json")
    }

    @Test("ExportFormat display names are non-empty")
    func displayNames() {
        for format in ExportFormat.allCases {
            #expect(!format.displayName.isEmpty)
        }
    }

    @Test("ExportFormat MIME types are valid")
    func mimeTypes() {
        #expect(ExportFormat.markdown.mimeType == "text/markdown")
        #expect(ExportFormat.plainText.mimeType == "text/plain")
        #expect(ExportFormat.json.mimeType == "application/json")
    }
}
