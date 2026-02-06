import Foundation

public enum DateHelpers {
    private nonisolated(unsafe) static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        f.dateTimeStyle = .named
        return f
    }()

    private nonisolated(unsafe) static let shortRelativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .named
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    public static func relativeString(from date: Date, relativeTo now: Date = .now) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: now)
    }

    public static func shortRelativeString(from date: Date, relativeTo now: Date = .now) -> String {
        shortRelativeFormatter.localizedString(for: date, relativeTo: now)
    }

    public static func timeString(from date: Date) -> String {
        timeFormatter.string(from: date)
    }

    public static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    public static func fullString(from date: Date) -> String {
        fullFormatter.string(from: date)
    }

    public static func durationString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        }
        return "0:\(String(format: "%02d", seconds))"
    }
}
