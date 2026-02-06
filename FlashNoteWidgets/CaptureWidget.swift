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
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)

                Text("Capture")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(.fill.tertiary, for: .widget)
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
