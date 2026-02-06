import SwiftUI
import SwiftData
import FlashNoteCore

@main
struct FlashNoteWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(for: [Note.self])
    }
}
