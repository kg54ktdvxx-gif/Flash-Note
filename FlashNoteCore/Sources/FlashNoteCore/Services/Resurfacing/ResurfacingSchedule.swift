import Foundation

public struct ResurfacingSchedule: Sendable {
    public let intervals: [TimeInterval]
    public let maxResurfaceCount: Int
    public let maxDailyNotifications: Int
    public let quietHoursStart: Int  // hour (24h), e.g. 22
    public let quietHoursEnd: Int    // hour (24h), e.g. 8

    public init(
        intervals: [TimeInterval],
        maxResurfaceCount: Int,
        maxDailyNotifications: Int,
        quietHoursStart: Int,
        quietHoursEnd: Int
    ) {
        precondition(!intervals.isEmpty, "intervals must not be empty")
        precondition(maxResurfaceCount > 0, "maxResurfaceCount must be positive")
        precondition(maxDailyNotifications > 0, "maxDailyNotifications must be positive")
        precondition((0...23).contains(quietHoursStart), "quietHoursStart must be 0-23")
        precondition((0...23).contains(quietHoursEnd), "quietHoursEnd must be 0-23")
        self.intervals = intervals
        self.maxResurfaceCount = maxResurfaceCount
        self.maxDailyNotifications = maxDailyNotifications
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }

    public static let `default` = ResurfacingSchedule(
        intervals: [
            1.0 * 86400,   // 1 day
            3.0 * 86400,   // 3 days
            7.0 * 86400,   // 7 days
            14.0 * 86400,  // 14 days
            30.0 * 86400   // 30 days
        ],
        maxResurfaceCount: 5,
        maxDailyNotifications: 3,
        quietHoursStart: 22,
        quietHoursEnd: 8
    )

    public func nextInterval(for resurfaceCount: Int) -> TimeInterval? {
        guard resurfaceCount >= 0, resurfaceCount < intervals.count else { return nil }
        return intervals[resurfaceCount]
    }
}
