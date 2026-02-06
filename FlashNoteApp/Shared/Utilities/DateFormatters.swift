import Foundation
import FlashNoteCore

enum DateFormatters {
    static func relativeTimestamp(for date: Date) -> String {
        DateHelpers.relativeString(from: date)
    }

    static func shortTimestamp(for date: Date) -> String {
        DateHelpers.shortRelativeString(from: date)
    }

    static func fullTimestamp(for date: Date) -> String {
        DateHelpers.fullString(from: date)
    }

    static func audioDuration(_ interval: TimeInterval) -> String {
        DateHelpers.durationString(from: interval)
    }
}
