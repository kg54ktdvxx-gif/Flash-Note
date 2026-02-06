import Foundation

public protocol ResurfacingService: Sendable {
    func computeNextResurfaceDate(for note: Note, schedule: ResurfacingSchedule) -> Date?
    func shouldResurface(note: Note, schedule: ResurfacingSchedule) -> Bool
}

public struct SpacedResurfacingService: ResurfacingService, Sendable {
    public init() {}

    public func computeNextResurfaceDate(for note: Note, schedule: ResurfacingSchedule) -> Date? {
        guard let interval = schedule.nextInterval(for: note.resurfaceCount) else {
            return nil
        }

        var targetDate = note.createdAt.addingTimeInterval(interval)

        // Enforce quiet hours
        var calendar = Calendar.current
        calendar.timeZone = .current
        let hour = calendar.component(.hour, from: targetDate)

        if hour >= schedule.quietHoursStart || hour < schedule.quietHoursEnd {
            // Target falls in quiet window — push to quietHoursEnd same day (early morning)
            // or next day (late evening).
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = schedule.quietHoursEnd
            components.minute = 0

            if hour >= schedule.quietHoursStart {
                // Late evening (e.g. 22:00–23:59) → push to 8am next day
                if let day = components.day { components.day = day + 1 }
            }
            // Early morning (e.g. 0:00–7:59) → push to 8am same day (no day bump needed)

            if let adjusted = calendar.date(from: components) {
                targetDate = adjusted
            }
        }

        return targetDate
    }

    public func shouldResurface(note: Note, schedule: ResurfacingSchedule) -> Bool {
        guard note.status == .active else { return false }
        guard !note.isTriaged else { return false }
        guard note.resurfaceCount < schedule.maxResurfaceCount else { return false }
        return true
    }
}
