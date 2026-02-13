import WidgetKit
import SwiftUI
import FlashNoteCore

struct RecentNotesProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentNotesEntry {
        RecentNotesEntry(date: .now, notes: [
            RecentNoteItem(id: UUID(), text: "Remember to call dentist", timeAgo: "2h ago"),
            RecentNoteItem(id: UUID(), text: "Great idea for the project", timeAgo: "5h ago"),
            RecentNoteItem(id: UUID(), text: "Buy groceries on the way home", timeAgo: "1d ago"),
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
    let id: UUID
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
            // Header — editorial section style
            HStack(spacing: 0) {
                Text("INBOX")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(entry.notes.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(WidgetColors.accent)
            }

            // Thin rule
            Rectangle()
                .fill(.primary)
                .frame(height: 1)

            if entry.notes.isEmpty {
                Spacer()
                Text("No notes yet")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.notes) { note in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.text)
                            .font(.system(.caption, design: .default))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(note.timeAgo)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }

                    if note.id != entry.notes.last?.id {
                        Rectangle()
                            .fill(.quaternary)
                            .frame(height: 0.5)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            Color(WidgetColors.background)
        }
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
