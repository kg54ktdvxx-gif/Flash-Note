import SwiftUI
import SwiftData
import FlashNoteCore

struct WatchInboxView: View {
    @Query(
        filter: #Predicate<Note> { $0.statusRaw != "deleted" },
        sort: \Note.createdAt,
        order: .reverse
    ) private var notes: [Note]

    var body: some View {
        NavigationStack {
            List {
                if notes.isEmpty {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(notes.prefix(20)) { note in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.previewText)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(2)

                            Text(DateHelpers.shortRelativeString(from: note.createdAt))
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Inbox")
        }
    }
}
