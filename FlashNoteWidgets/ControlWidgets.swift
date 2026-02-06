import WidgetKit
import SwiftUI

struct CaptureControlWidget: ControlWidget {
    let kind = "CaptureControlWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenCaptureIntent()) {
                Label("Capture", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Quick Capture")
        .description("Tap to capture a thought.")
    }
}
