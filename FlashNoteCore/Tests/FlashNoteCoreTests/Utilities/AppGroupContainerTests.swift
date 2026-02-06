import Testing
import Foundation
@testable import FlashNoteCore

@Suite("AppGroupContainer")
struct AppGroupContainerTests {

    @Test("groupIdentifier is the expected value")
    func groupIdentifier() {
        #expect(AppGroupContainer.groupIdentifier == "group.com.flashnote.shared")
    }

    @Test("sharedContainerURL returns a valid URL (fallback in test environment)")
    func sharedContainerURL() {
        // In tests, App Group won't be configured — should fallback to Documents
        let url = AppGroupContainer.sharedContainerURL
        #expect(url.isFileURL)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("hotBufferFileURL has .jsonl extension")
    func hotBufferFileURL() {
        let url = AppGroupContainer.hotBufferFileURL
        #expect(url.pathExtension == "jsonl")
        #expect(url.lastPathComponent == "hot_capture_buffer.jsonl")
    }

    @Test("audioDirectory path ends with Audio")
    func audioDirectory() {
        let url = AppGroupContainer.audioDirectory
        #expect(url.lastPathComponent == "Audio")
    }

    @Test("audioFileURL appends filename to audio directory")
    func audioFileURL() {
        let url = AppGroupContainer.audioFileURL(for: "test.m4a")
        #expect(url.lastPathComponent == "test.m4a")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Audio")
    }

    @Test("sharedDefaults returns a valid UserDefaults (fallback in test environment)")
    func sharedDefaults() {
        // In test, App Group suite may not be available — should fallback to .standard
        let defaults = AppGroupContainer.sharedDefaults
        // Just verify it doesn't crash and returns a usable instance
        defaults.set("test_value", forKey: "flashnote_test_key")
        #expect(defaults.string(forKey: "flashnote_test_key") == "test_value")
        defaults.removeObject(forKey: "flashnote_test_key")
    }
}
