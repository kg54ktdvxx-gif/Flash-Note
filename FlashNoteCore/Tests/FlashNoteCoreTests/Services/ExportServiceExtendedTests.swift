import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("DefaultExportService — Extended")
struct ExportServiceExtendedTests {

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

    // MARK: - exportToFile

    @Test("exportToFile creates a file on disk")
    func exportToFileCreatesFile() throws {
        let notes = try makeNotes(texts: ["Test export"])
        let url = try service.exportToFile(notes: notes, format: .plainText)
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("exportToFile uses correct file extension")
    func exportToFileExtension() throws {
        let notes = try makeNotes(texts: ["Test"])

        for format in ExportFormat.allCases {
            let url = try service.exportToFile(notes: notes, format: format)
            defer { try? FileManager.default.removeItem(at: url) }
            #expect(url.pathExtension == format.fileExtension)
        }
    }

    @Test("exportToFile content is readable and correct")
    func exportToFileContent() throws {
        let notes = try makeNotes(texts: ["Hello world"])
        let url = try service.exportToFile(notes: notes, format: .plainText)
        defer { try? FileManager.default.removeItem(at: url) }

        let content = try String(contentsOf: url, encoding: .utf8)
        #expect(content.contains("Hello world"))
    }

    // MARK: - Special characters in export

    @Test("markdown export handles special characters")
    func markdownSpecialChars() throws {
        let notes = try makeNotes(texts: ["# Not a heading", "**not bold**", "[not a link](url)"])
        let result = service.export(notes: notes, format: .markdown)
        #expect(result.contains("# Not a heading"))
        #expect(result.contains("**not bold**"))
    }

    @Test("JSON export handles unicode")
    func jsonUnicode() throws {
        let notes = try makeNotes(texts: ["Hello 🌍 Émoji café"])
        let result = service.export(notes: notes, format: .json)
        let data = result.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        #expect(parsed?.first?["text"] as? String == "Hello 🌍 Émoji café")
    }

    @Test("plain text export handles very long notes")
    func plainTextLongNote() throws {
        let longText = String(repeating: "A", count: 10_000)
        let notes = try makeNotes(texts: [longText])
        let result = service.export(notes: notes, format: .plainText)
        #expect(result.contains(longText))
    }
}
