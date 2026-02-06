import SwiftUI

struct WatchContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchCaptureView()
                .tag(0)

            WatchInboxView()
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
    }
}
