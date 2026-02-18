import Foundation

public struct BufferEntry: Codable, Sendable {
    public let id: UUID
    public let text: String
    public let sourceRaw: String
    public let capturedAt: Date
    public let audioFileName: String?

    public var source: CaptureSource {
        CaptureSource(rawValue: sourceRaw) ?? .keyboard
    }

    /// Maximum text length for a buffer entry. Inputs exceeding this limit are truncated.
    public static let maxTextLength = 50_000

    public init(
        text: String,
        source: CaptureSource,
        audioFileName: String? = nil
    ) {
        self.id = UUID()
        if text.count > Self.maxTextLength {
            self.text = String(text.prefix(Self.maxTextLength)) + "\n... (truncated)"
        } else {
            self.text = text
        }
        self.sourceRaw = source.rawValue
        self.capturedAt = .now
        self.audioFileName = audioFileName
    }
}
