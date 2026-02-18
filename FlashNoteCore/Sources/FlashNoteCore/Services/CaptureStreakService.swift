import Foundation
import SwiftData

public enum CaptureStreakService {
    @MainActor
    public static func currentStreak(in context: ModelContext) -> Int {
        let predicate = #Predicate<Note> { $0.statusRaw != "deleted" }
        var descriptor = FetchDescriptor<Note>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.propertiesToFetch = [\.createdAt]

        guard let notes = try? context.fetch(descriptor) else { return 0 }

        let calendar = Calendar.current
        var uniqueDays = Set<Date>()
        for note in notes {
            uniqueDays.insert(calendar.startOfDay(for: note.createdAt))
        }

        let sortedDays = uniqueDays.sorted(by: >)
        guard !sortedDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: .now)

        // If no note today, streak is 0
        guard sortedDays.first == today else { return 0 }

        var streak = 1
        for i in 1..<sortedDays.count {
            guard let expectedDay = calendar.date(byAdding: .day, value: -i, to: today) else { break }
            if sortedDays[i] == expectedDay {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
}
