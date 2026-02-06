import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("SpacedResurfacingService")
struct ResurfacingServiceTests {

    private let service = SpacedResurfacingService()
    private let schedule = ResurfacingSchedule.default

    private func makeNote(
        text: String = "test",
        status: NoteStatus = .active,
        isTriaged: Bool = false,
        resurfaceCount: Int = 0,
        createdAt: Date = .now
    ) throws -> (Note, ModelContext) {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let note = Note(text: text)
        context.insert(note)
        note.status = status
        note.isTriaged = isTriaged
        note.resurfaceCount = resurfaceCount
        note.createdAt = createdAt
        return (note, context)
    }

    // MARK: - shouldResurface

    @Test("shouldResurface returns true for fresh active untriaged note")
    func shouldResurfaceTrue() throws {
        let (note, _) = try makeNote()
        #expect(service.shouldResurface(note: note, schedule: schedule) == true)
    }

    @Test("shouldResurface returns false for archived note")
    func shouldResurfaceFalseArchived() throws {
        let (note, _) = try makeNote(status: .archived)
        #expect(service.shouldResurface(note: note, schedule: schedule) == false)
    }

    @Test("shouldResurface returns false for deleted note")
    func shouldResurfaceFalseDeleted() throws {
        let (note, _) = try makeNote(status: .deleted)
        #expect(service.shouldResurface(note: note, schedule: schedule) == false)
    }

    @Test("shouldResurface returns false for triaged note")
    func shouldResurfaceFalseTriaged() throws {
        let (note, _) = try makeNote(isTriaged: true)
        #expect(service.shouldResurface(note: note, schedule: schedule) == false)
    }

    @Test("shouldResurface returns false when resurfaceCount >= max")
    func shouldResurfaceFalseMaxed() throws {
        let (note, _) = try makeNote(resurfaceCount: 5)
        #expect(service.shouldResurface(note: note, schedule: schedule) == false)
    }

    @Test("shouldResurface returns true at count 4 (one below max)")
    func shouldResurfaceTrueJustBelowMax() throws {
        let (note, _) = try makeNote(resurfaceCount: 4)
        #expect(service.shouldResurface(note: note, schedule: schedule) == true)
    }

    // MARK: - computeNextResurfaceDate

    @Test("computeNextResurfaceDate returns nil when resurfaceCount >= max")
    func computeDateNilWhenMaxed() throws {
        let (note, _) = try makeNote(resurfaceCount: 5)
        #expect(service.computeNextResurfaceDate(for: note, schedule: schedule) == nil)
    }

    @Test("computeNextResurfaceDate returns date 1 day after creation for count 0")
    func computeDateFirstResurface() throws {
        let createdAt = Date(timeIntervalSince1970: 1706000000) // Some fixed date
        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)

        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
        #expect(result != nil)

        // Should be approximately 1 day later (may be adjusted for quiet hours)
        let diff = result!.timeIntervalSince(createdAt)
        // At least 1 day (could be more if quiet hours pushed it)
        #expect(diff >= 86400)
        // But no more than 1 day + 10 hours (worst case: 11pm → 8am next day)
        #expect(diff <= 86400 + 36000)
    }

    @Test("computeNextResurfaceDate at count 4 returns ~30 days later")
    func computeDateLastResurface() throws {
        let createdAt = Date(timeIntervalSince1970: 1706000000)
        let (note, _) = try makeNote(resurfaceCount: 4, createdAt: createdAt)

        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
        #expect(result != nil)
        let diff = result!.timeIntervalSince(createdAt)
        #expect(diff >= 30 * 86400)
        #expect(diff <= 30 * 86400 + 36000)
    }

    // MARK: - Quiet hours

    @Test("late evening (23:00) is pushed to 8am next day")
    func quietHoursLateEvening() throws {
        // Create a date that, after adding 1 day, lands at 23:00
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 23  // 11 PM
        components.minute = 0
        let createdAt = calendar.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)

        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
        #expect(result != nil)

        let resultComponents = calendar.dateComponents([.hour, .day], from: result!)
        #expect(resultComponents.hour == 8)
        // Should be day 12 (created day 10 + 1 day = day 11 at 23:00, pushed to day 12 at 8:00)
        #expect(resultComponents.day == 12)
    }

    @Test("early morning (3:00) is pushed to 8am same day")
    func quietHoursEarlyMorning() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 3  // 3 AM
        components.minute = 0
        let createdAt = calendar.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)

        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
        #expect(result != nil)

        let resultComponents = calendar.dateComponents([.hour, .day], from: result!)
        #expect(resultComponents.hour == 8)
        // Created at day 10 3AM + 1 day = day 11 3AM → pushed to day 11 8AM (same day)
        #expect(resultComponents.day == 11)
    }

    @Test("daytime (14:00) is not adjusted")
    func noAdjustmentDaytime() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 14  // 2 PM
        components.minute = 0
        let createdAt = calendar.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)

        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
        #expect(result != nil)

        let resultComponents = calendar.dateComponents([.hour, .day], from: result!)
        // Created at day 10 14:00 + 1 day = day 11 14:00 — no quiet hours adjustment
        #expect(resultComponents.hour == 14)
        #expect(resultComponents.day == 11)
    }

    @Test("boundary: exactly 22:00 is in quiet hours")
    func quietHoursBoundaryStart() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 22
        components.minute = 0
        let createdAt = calendar.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)
        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)!

        let resultComponents = calendar.dateComponents([.hour], from: result)
        #expect(resultComponents.hour == 8)
    }

    @Test("boundary: exactly 8:00 is NOT in quiet hours")
    func quietHoursBoundaryEnd() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 8
        components.minute = 0
        let createdAt = calendar.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)
        let result = service.computeNextResurfaceDate(for: note, schedule: schedule)!

        let resultComponents = calendar.dateComponents([.hour], from: result)
        // 8:00 is NOT >= 22 and NOT < 8, so no adjustment
        #expect(resultComponents.hour == 8)
    }
}
