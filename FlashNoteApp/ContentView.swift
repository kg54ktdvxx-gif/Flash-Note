import SwiftUI
import SwiftData
import FlashNoteCore

struct ContentView: View {
    @Environment(NavigationRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Capture", systemImage: "plus.circle.fill", value: AppTab.capture) {
                CaptureView()
            }

            Tab("Inbox", systemImage: "tray.fill", value: AppTab.inbox) {
                InboxView()
            }
        }
        .onOpenURL { url in
            router.handle(url: url)
        }
        .onAppear {
            BufferSyncService.flush(to: modelContext)
        }
    }
}
