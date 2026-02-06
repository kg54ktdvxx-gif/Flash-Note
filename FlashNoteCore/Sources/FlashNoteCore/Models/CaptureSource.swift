import Foundation

public enum CaptureSource: String, Codable, Sendable, CaseIterable {
    case keyboard
    case voice
    case share
    case siri
    case watch
    case widget

    public var displayName: String {
        switch self {
        case .keyboard: "Typed"
        case .voice: "Voice"
        case .share: "Shared"
        case .siri: "Siri"
        case .watch: "Watch"
        case .widget: "Widget"
        }
    }

    public var iconName: String {
        switch self {
        case .keyboard: "keyboard"
        case .voice: "mic.fill"
        case .share: "square.and.arrow.up"
        case .siri: "waveform"
        case .watch: "applewatch"
        case .widget: "square.grid.2x2"
        }
    }
}
