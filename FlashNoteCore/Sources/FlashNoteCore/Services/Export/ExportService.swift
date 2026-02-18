import Foundation

public protocol ExportService: Sendable {
    func export(notes: [Note], format: ExportFormat) -> String
    func exportToFile(notes: [Note], format: ExportFormat) throws -> URL
}

public struct DefaultExportService: ExportService, Sendable {
    public init() {}

    public func export(notes: [Note], format: ExportFormat) -> String {
        switch format {
        case .markdown:
            return exportMarkdown(notes: notes)
        case .plainText:
            return exportPlainText(notes: notes)
        case .json:
            return exportJSON(notes: notes)
        }
    }

    public func exportToFile(notes: [Note], format: ExportFormat) throws -> URL {
        let content = export(notes: notes, format: format)
        let fileName = "FlashNote_Export_\(DateHelpers.dateString(from: .now)).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }

    private func exportMarkdown(notes: [Note]) -> String {
        var lines = ["# FlashNote Export", ""]
        for note in notes {
            lines.append("## \(DateHelpers.fullString(from: note.createdAt))")
            lines.append("")
            lines.append(note.text)
            lines.append("")
            lines.append("---")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func exportPlainText(notes: [Note]) -> String {
        var lines: [String] = []
        for note in notes {
            lines.append("[\(DateHelpers.fullString(from: note.createdAt))]")
            lines.append(note.text)
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func exportJSON(notes: [Note]) -> String {
        struct ExportNote: Codable {
            let text: String
            let createdAt: String
            let source: String
            let status: String
        }

        let isoFormatter = ISO8601DateFormatter()
        let exportNotes = notes.map { note in
            ExportNote(
                text: note.text,
                createdAt: isoFormatter.string(from: note.createdAt),
                source: note.sourceRaw,
                status: note.statusRaw
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(exportNotes)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            FNLog.export.error("JSON export encoding failed: \(error)")
            return "[]"
        }
    }
}
