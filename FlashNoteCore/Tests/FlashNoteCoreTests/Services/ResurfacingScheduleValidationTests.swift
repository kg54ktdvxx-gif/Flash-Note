import Testing
import Foundation
@testable import FlashNoteCore

@Suite("ResurfacingSchedule Validation")
struct ResurfacingScheduleValidationTests {

    @Test("single interval is valid")
    func singleInterval() {
        let schedule = ResurfacingSchedule(
            intervals: [3600],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        #expect(schedule.intervals.count == 1)
        #expect(schedule.nextInterval(for: 0) == 3600)
        #expect(schedule.nextInterval(for: 1) == nil)
    }

    @Test("quietHoursStart boundary 0 is valid")
    func quietHoursStartZero() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 0,
            quietHoursEnd: 8
        )
        #expect(schedule.quietHoursStart == 0)
    }

    @Test("quietHoursStart boundary 23 is valid")
    func quietHoursStartMax() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 23,
            quietHoursEnd: 8
        )
        #expect(schedule.quietHoursStart == 23)
    }

    @Test("quietHoursEnd boundary 0 is valid")
    func quietHoursEndZero() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 22,
            quietHoursEnd: 0
        )
        #expect(schedule.quietHoursEnd == 0)
    }

    @Test("quietHoursEnd boundary 23 is valid")
    func quietHoursEndMax() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 0,
            quietHoursEnd: 23
        )
        #expect(schedule.quietHoursEnd == 23)
    }

    @Test("maxResurfaceCount of 1 is valid")
    func minResurfaceCount() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        #expect(schedule.maxResurfaceCount == 1)
    }

    @Test("maxDailyNotifications of 1 is valid")
    func minDailyNotifications() {
        let schedule = ResurfacingSchedule(
            intervals: [86400],
            maxResurfaceCount: 1,
            maxDailyNotifications: 1,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        #expect(schedule.maxDailyNotifications == 1)
    }

    @Test("large values are accepted")
    func largeValues() {
        let schedule = ResurfacingSchedule(
            intervals: Array(repeating: 86400, count: 100),
            maxResurfaceCount: 1000,
            maxDailyNotifications: 50,
            quietHoursStart: 23,
            quietHoursEnd: 23
        )
        #expect(schedule.intervals.count == 100)
        #expect(schedule.maxResurfaceCount == 1000)
        #expect(schedule.maxDailyNotifications == 50)
    }
}
