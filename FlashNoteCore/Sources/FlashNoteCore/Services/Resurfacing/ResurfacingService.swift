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
            if hour >= schedule.quietHoursStart {
                // Late evening (e.g. 22:00–23:59) → push to 8am next day
                // I3 fix: Use Calendar.date(byAdding:) instead of raw day+1 increment,
                // which fails on month boundaries (e.g. Dec 31 → day 32 → nil).
                if let nextDay = calendar.date(byAdding: .day, value: 1, to: targetDate),
                   let adjusted = calendar.date(bySettingHour: schedule.quietHoursEnd, minute: 0, second: 0, of: nextDay) {
                    targetDate = adjusted
                }
            } else {
                // Early morning (e.g. 0:00–7:59) → push to 8am same day
                if let adjusted = calendar.date(bySettingHour: schedule.quietHoursEnd, minute: 0, second: 0, of: targetDate) {
                    targetDate = adjusted
                }
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
