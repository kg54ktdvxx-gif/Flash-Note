import Foundation

public enum ExportFormat: String, CaseIterable, Sendable {
    case markdown
    case plainText
    case json

    public var displayName: String {
        switch self {
        case .markdown: "Markdown"
        case .plainText: "Plain Text"
        case .json: "JSON"
        }
    }

    public var fileExtension: String {
        switch self {
        case .markdown: "md"
        case .plainText: "txt"
        case .json: "json"
        }
    }

    public var mimeType: String {
        switch self {
        case .markdown: "text/markdown"
        case .plainText: "text/plain"
        case .json: "application/json"
        }
    }
}
