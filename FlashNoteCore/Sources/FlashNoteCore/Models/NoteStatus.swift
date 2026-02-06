import Foundation

public enum NoteStatus: String, Codable, Sendable, CaseIterable {
    case active
    case archived
    case task
    case deleted
}
