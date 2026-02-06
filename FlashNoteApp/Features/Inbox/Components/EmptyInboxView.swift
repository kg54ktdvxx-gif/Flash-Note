import SwiftUI

struct EmptyInboxView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Notes Yet", systemImage: "note.text")
        } description: {
            Text("Your captured thoughts will appear here.\nSwitch to the Capture tab to jot something down.")
                .font(AppTypography.body)
        } actions: {
            // Intentionally empty — the user navigates via tabs
        }
    }
}
