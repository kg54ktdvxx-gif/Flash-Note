import WidgetKit
import SwiftUI

@main
struct FlashNoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaptureWidget()
        RecentNotesWidget()
    }
}
