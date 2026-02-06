import Foundation

public enum AppGroupContainer {
    public static let groupIdentifier = "group.com.flashnote.shared"

    public static var sharedContainerURL: URL {
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupIdentifier
        ) {
            return url
        }
        // Fallback to Documents when App Group entitlement is missing (e.g. tests, previews).
        // Logged so it's visible in Console during development.
        FNLog.buffer.warning("App Group '\(groupIdentifier)' unavailable — falling back to Documents")
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
        UserDefaults(suiteName: groupIdentifier) ?? .standard
    }

    public static func audioFileURL(for fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }
}
