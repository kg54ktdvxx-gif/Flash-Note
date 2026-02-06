import Testing
import Foundation
@testable import FlashNoteCore

@Suite("ResurfacingSchedule")
struct ResurfacingScheduleTests {

    @Test("default schedule has 5 intervals")
    func defaultIntervalCount() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.intervals.count == 5)
        #expect(schedule.maxResurfaceCount == 5)
    }

    @Test("default intervals are 1, 3, 7, 14, 30 days in seconds")
    func defaultIntervalValues() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.intervals[0] == 86400)       // 1 day
        #expect(schedule.intervals[1] == 3 * 86400)   // 3 days
        #expect(schedule.intervals[2] == 7 * 86400)   // 7 days
        #expect(schedule.intervals[3] == 14 * 86400)  // 14 days
        #expect(schedule.intervals[4] == 30 * 86400)  // 30 days
    }

    @Test("nextInterval returns correct interval for valid counts")
    func nextIntervalValid() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.nextInterval(for: 0) == 86400.0)
        #expect(schedule.nextInterval(for: 4) == 30.0 * 86400)
    }

    @Test("nextInterval returns nil when count >= intervals.count")
    func nextIntervalOutOfBounds() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.nextInterval(for: 5) == nil)
        #expect(schedule.nextInterval(for: 100) == nil)
    }

    @Test("nextInterval returns nil for negative count")
    func nextIntervalNegative() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.nextInterval(for: -1) == nil)
        #expect(schedule.nextInterval(for: -100) == nil)
    }

    @Test("default quiet hours are 22-8")
    func defaultQuietHours() {
        let schedule = ResurfacingSchedule.default
        #expect(schedule.quietHoursStart == 22)
        #expect(schedule.quietHoursEnd == 8)
    }

    @Test("custom schedule respects all fields")
    func customSchedule() {
        let schedule = ResurfacingSchedule(
            intervals: [3600, 7200],
            maxResurfaceCount: 2,
            maxDailyNotifications: 1,
            quietHoursStart: 20,
            quietHoursEnd: 9
        )
        #expect(schedule.intervals.count == 2)
        #expect(schedule.maxResurfaceCount == 2)
        #expect(schedule.maxDailyNotifications == 1)
        #expect(schedule.quietHoursStart == 20)
        #expect(schedule.quietHoursEnd == 9)
        #expect(schedule.nextInterval(for: 0) == 3600)
        #expect(schedule.nextInterval(for: 1) == 7200)
        #expect(schedule.nextInterval(for: 2) == nil)
    }
}
