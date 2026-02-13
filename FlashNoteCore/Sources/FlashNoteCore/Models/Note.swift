import Foundation
import SwiftData

@Model
public final class Note {
    public var id: UUID
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date
    public var statusRaw: String
    public var sourceRaw: String
    public var audioFileName: String?
    public var audioDuration: TimeInterval?
    public var transcriptionConfidence: Float?
    public var resurfaceCount: Int
    public var lastResurfacedAt: Date?
    public var nextResurfaceAt: Date?
    public var isTriaged: Bool
    public var isTask: Bool
    public var isTaskCompleted: Bool
    public var spotlightID: String?
    public var isPinned: Bool
    public var pinnedAt: Date?

    @Transient
    public var status: NoteStatus {
        get { NoteStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    @Transient
    public var source: CaptureSource {
        get { CaptureSource(rawValue: sourceRaw) ?? .keyboard }
        set { sourceRaw = newValue.rawValue }
    }

    @Transient
    public var audioURL: URL? {
        guard let audioFileName else { return nil }
        return AppGroupContainer.audioFileURL(for: audioFileName)
    }

    @Transient
    public var wordCount: Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    @Transient
    public var previewText: String {
        if text.count <= 100 { return text }
        return String(text.prefix(100)) + "..."
    }

    @Transient
    public var relativeTimestamp: String {
        DateHelpers.relativeString(from: createdAt)
    }

    public func togglePin() {
        isPinned.toggle()
        pinnedAt = isPinned ? .now : nil
        updatedAt = .now
    }

    public init(
        text: String,
        source: CaptureSource = .keyboard,
        audioFileName: String? = nil,
        audioDuration: TimeInterval? = nil,
        transcriptionConfidence: Float? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.createdAt = .now
        self.updatedAt = .now
        self.statusRaw = NoteStatus.active.rawValue
        self.sourceRaw = source.rawValue
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
        self.transcriptionConfidence = transcriptionConfidence
        self.resurfaceCount = 0
        self.lastResurfacedAt = nil
        self.nextResurfaceAt = nil
        self.isTriaged = false
        self.isTask = false
        self.isTaskCompleted = false
        self.spotlightID = nil
        self.isPinned = false
        self.pinnedAt = nil
    }
}
