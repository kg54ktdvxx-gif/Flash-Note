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

    public init(
        text: String,
        source: CaptureSource,
        audioFileName: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.sourceRaw = source.rawValue
        self.capturedAt = .now
        self.audioFileName = audioFileName
    }
}
