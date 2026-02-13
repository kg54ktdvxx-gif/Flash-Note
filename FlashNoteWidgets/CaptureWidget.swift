import WidgetKit
import SwiftUI

struct CaptureWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaptureWidgetEntry {
        CaptureWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (CaptureWidgetEntry) -> Void) {
        completion(CaptureWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaptureWidgetEntry>) -> Void) {
        let entry = CaptureWidgetEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct CaptureWidgetEntry: TimelineEntry {
    let date: Date
}

struct CaptureWidgetView: View {
    var entry: CaptureWidgetProvider.Entry

    private static let captureURL = URL(string: "flashnote://capture")!

    var body: some View {
        Link(destination: Self.captureURL) {
            VStack(spacing: 10) {
                // Editorial "Write" prompt — serif, bold
                Text("Write")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(.primary)

                // Vermillion accent line
                Rectangle()
                    .fill(WidgetColors.accent)
                    .frame(width: 20, height: 1.5)

                // Monospace hint
                Text("TAP TO CAPTURE")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(WidgetColors.background)
        }
    }
}

struct CaptureWidget: Widget {
    let kind = "CaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaptureWidgetProvider()) { entry in
            CaptureWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Capture")
        .description("Tap to instantly capture a thought.")
        .supportedFamilies([.systemSmall])
    }
}
