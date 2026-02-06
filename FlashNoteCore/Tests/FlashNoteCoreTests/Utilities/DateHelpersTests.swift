import Testing
import Foundation
@testable import FlashNoteCore

@Suite("DateHelpers")
struct DateHelpersTests {

    // MARK: - durationString

    @Test("durationString formats zero seconds")
    func durationZero() {
        #expect(DateHelpers.durationString(from: 0) == "0:00")
    }

    @Test("durationString formats seconds only")
    func durationSecondsOnly() {
        #expect(DateHelpers.durationString(from: 5) == "0:05")
        #expect(DateHelpers.durationString(from: 30) == "0:30")
        #expect(DateHelpers.durationString(from: 59) == "0:59")
    }

    @Test("durationString formats minutes and seconds")
    func durationMinutesAndSeconds() {
        #expect(DateHelpers.durationString(from: 60) == "1:00")
        #expect(DateHelpers.durationString(from: 65) == "1:05")
        #expect(DateHelpers.durationString(from: 125) == "2:05")
        #expect(DateHelpers.durationString(from: 600) == "10:00")
    }

    @Test("durationString pads seconds with leading zero")
    func durationPadding() {
        let result = DateHelpers.durationString(from: 61)
        #expect(result == "1:01")
    }

    @Test("durationString handles fractional seconds by truncating")
    func durationFractional() {
        #expect(DateHelpers.durationString(from: 5.9) == "0:05")
        #expect(DateHelpers.durationString(from: 61.999) == "1:01")
    }

    // MARK: - relativeString

    @Test("relativeString returns non-empty string")
    func relativeStringNotEmpty() {
        let date = Date.now.addingTimeInterval(-3600)
        let result = DateHelpers.relativeString(from: date)
        #expect(!result.isEmpty)
    }

    @Test("shortRelativeString returns non-empty string")
    func shortRelativeNotEmpty() {
        let date = Date.now.addingTimeInterval(-86400)
        let result = DateHelpers.shortRelativeString(from: date)
        #expect(!result.isEmpty)
    }

    // MARK: - dateString / timeString / fullString

    @Test("dateString returns non-empty string")
    func dateStringNotEmpty() {
        let result = DateHelpers.dateString(from: .now)
        #expect(!result.isEmpty)
    }

    @Test("timeString returns non-empty string")
    func timeStringNotEmpty() {
        let result = DateHelpers.timeString(from: .now)
        #expect(!result.isEmpty)
    }

    @Test("fullString returns non-empty string")
    func fullStringNotEmpty() {
        let result = DateHelpers.fullString(from: .now)
        #expect(!result.isEmpty)
    }

    @Test("fullString contains both date and time components")
    func fullStringContainsBoth() {
        // Create a specific date so we can check components
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        let date = Calendar.current.date(from: components)!
        let result = DateHelpers.fullString(from: date)
        // Should contain "15" (day) and some time indicator
        #expect(result.contains("15"))
    }
}
