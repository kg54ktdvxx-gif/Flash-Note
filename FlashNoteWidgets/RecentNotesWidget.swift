import WidgetKit
import SwiftUI
import FlashNoteCore

struct RecentNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentNotesEntry {
        RecentNotesEntry(date: .now, notes: [
            RecentNoteItem(text: "Remember to call dentist", timeAgo: "2h ago"),
            RecentNoteItem(text: "Great idea for the project", timeAgo: "5h ago"),
            RecentNoteItem(text: "Buy groceries on the way home", timeAgo: "1d ago"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentNotesEntry) -> Void) {
        let notes = loadRecentNotes()
        completion(RecentNotesEntry(date: .now, notes: notes))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentNotesEntry>) -> Void) {
        let notes = loadRecentNotes()
        let entry = RecentNotesEntry(date: .now, notes: notes)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadRecentNotes() -> [RecentNoteItem] {
        let defaults = AppGroupContainer.sharedDefaults
        guard let data = defaults.data(forKey: "recentNotes"),
              let items = try? JSONDecoder().decode([RecentNoteItem].self, from: data) else {
            return []
        }
        return Array(items.prefix(3))
    }
}

struct RecentNoteItem: Codable, Identifiable {
    var id: String { text + timeAgo }
    let text: String
    let timeAgo: String
}

struct RecentNotesEntry: TimelineEntry {
    let date: Date
    let notes: [RecentNoteItem]
}

struct RecentNotesWidgetView: View {
    var entry: RecentNotesProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tray.fill")
                    .foregroundStyle(.blue)
                Text("Recent Notes")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                Spacer()
            }

            if entry.notes.isEmpty {
                Text("No notes yet")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.notes) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.text)
                            .font(.system(.caption, design: .rounded))
                            .lineLimit(1)

                        Text(note.timeAgo)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct RecentNotesWidget: Widget {
    let kind = "RecentNotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentNotesProvider()) { entry in
            RecentNotesWidgetView(entry: entry)
        }
        .configurationDisplayName("Recent Notes")
        .description("See your latest captured thoughts.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
