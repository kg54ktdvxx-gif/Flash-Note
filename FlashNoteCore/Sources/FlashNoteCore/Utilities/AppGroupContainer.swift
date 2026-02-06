import Foundation

public enum AppGroupContainer {
    public static let groupIdentifier = "group.com.flashnote.shared"

    public static var sharedContainerURL: URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        ) else {
            fatalError("App Group '\(groupIdentifier)' not configured")
        }
        return url
    }

    public static var hotBufferFileURL: URL {
        sharedContainerURL.appendingPathComponent("hot_capture_buffer.jsonl")
    }

    public static var audioDirectory: URL {
        let url = sharedContainerURL.appendingPathComponent("Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public static var sharedDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Cannot create UserDefaults for App Group '\(groupIdentifier)'")
        }
        return defaults
    }

    public static func audioFileURL(for fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }
}
