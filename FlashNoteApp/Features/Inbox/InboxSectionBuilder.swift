import Foundation
import FlashNoteCore

enum InboxSectionBuilder {
    struct Section: Identifiable {
        let title: String
        let notes: [Note]
        var id: String { title }
    }

    static func build(from notes: [Note]) -> [Section] {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)

        guard let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
              let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else { return [Section(title: "All", notes: notes)] }

        var pinned: [Note] = []
        var today: [Note] = []
        var yesterday: [Note] = []
        var thisWeek: [Note] = []
        var thisMonth: [Note] = []
        var older: [Note] = []

        for note in notes {
            if note.isPinned {
                pinned.append(note)
                continue
            }

            let created = note.createdAt
            if created >= startOfToday {
                today.append(note)
            } else if created >= startOfYesterday {
                yesterday.append(note)
            } else if created >= startOfWeek {
                thisWeek.append(note)
            } else if created >= startOfMonth {
                thisMonth.append(note)
            } else {
                older.append(note)
            }
        }

        // Sort pinned by pinnedAt (most recently pinned first)
        pinned.sort { ($0.pinnedAt ?? .distantPast) > ($1.pinnedAt ?? .distantPast) }

        var sections: [Section] = []
        if !pinned.isEmpty { sections.append(Section(title: "Pinned", notes: pinned)) }
        if !today.isEmpty { sections.append(Section(title: "Today", notes: today)) }
        if !yesterday.isEmpty { sections.append(Section(title: "Yesterday", notes: yesterday)) }
        if !thisWeek.isEmpty { sections.append(Section(title: "This Week", notes: thisWeek)) }
        if !thisMonth.isEmpty { sections.append(Section(title: "This Month", notes: thisMonth)) }
        if !older.isEmpty { sections.append(Section(title: "Older", notes: older)) }

        return sections
    }
}
