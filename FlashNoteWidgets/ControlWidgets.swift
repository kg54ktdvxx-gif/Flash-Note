import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 18.0, *)
struct CaptureControlWidget: ControlWidget {
    let kind = "CaptureControlWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenCaptureAppIntent()) {
                Label("Capture", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Quick Capture")
        .description("Tap to capture a thought.")
    }
}

@available(iOS 18.0, *)
struct OpenCaptureAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Capture"
    static let description: IntentDescription = "Opens FlashNote capture screen."
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
