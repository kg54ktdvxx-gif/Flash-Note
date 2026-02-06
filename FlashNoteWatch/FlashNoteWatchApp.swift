import SwiftUI
import SwiftData
import FlashNoteCore

@main
struct FlashNoteWatchApp: App {
    init() {
        WatchConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
        .modelContainer(for: [Note.self])
    }
}
