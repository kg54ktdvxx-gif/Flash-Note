import SwiftUI
import SwiftData
import FlashNoteCore

@main
struct FlashNoteApp: App {
    private let container: DependencyContainer

    init() {
        container = DependencyContainer.shared
        container.setupNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container.navigationRouter)
        }
        .modelContainer(container.modelContainer)
    }
}
