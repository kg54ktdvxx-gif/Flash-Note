import Foundation

public struct TranscriptionResult: Sendable {
    public let text: String
    public let confidence: Float
    public let isFinal: Bool
    public let audioFileName: String?
    public let audioDuration: TimeInterval?

    public init(
        text: String,
        confidence: Float = 1.0,
        isFinal: Bool = false,
        audioFileName: String? = nil,
        audioDuration: TimeInterval? = nil
    ) {
        self.text = text
        self.confidence = confidence
        self.isFinal = isFinal
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
    }
}
