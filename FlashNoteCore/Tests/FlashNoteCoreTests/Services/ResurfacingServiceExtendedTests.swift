import Testing
import SwiftData
import Foundation
@testable import FlashNoteCore

@Suite("SpacedResurfacingService — Extended")
struct ResurfacingServiceExtendedTests {

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

    // MARK: - shouldResurface with .task status

    @Test("shouldResurface returns false for task status note")
    func shouldResurfaceFalseTask() throws {
        let (note, _) = try makeNote(status: .task)
        #expect(service.shouldResurface(note: note, schedule: schedule) == false)
    }

    // MARK: - Edge cases for computeNextResurfaceDate

    @Test("computeNextResurfaceDate returns nil for negative resurfaceCount")
    func computeDateNilNegativeCount() throws {
        let (note, _) = try makeNote(resurfaceCount: -1)
        // The schedule's nextInterval(for: -1) returns nil, so date should be nil
        #expect(service.computeNextResurfaceDate(for: note, schedule: schedule) == nil)
    }

    @Test("computeNextResurfaceDate uses each interval correctly")
    func computeDateAllIntervals() throws {
        let createdAt = Date(timeIntervalSince1970: 1706000000)
        let expectedDays: [TimeInterval] = [1, 3, 7, 14, 30]

        for (count, days) in expectedDays.enumerated() {
            let (note, _) = try makeNote(resurfaceCount: count, createdAt: createdAt)
            let result = service.computeNextResurfaceDate(for: note, schedule: schedule)
            #expect(result != nil)
            let diff = result!.timeIntervalSince(createdAt)
            // At least the expected interval
            #expect(diff >= days * 86400)
            // But no more than the interval + 10 hours (quiet hours adjustment)
            #expect(diff <= days * 86400 + 36000)
        }
    }

    // MARK: - Custom schedule

    @Test("shouldResurface respects custom maxResurfaceCount")
    func customMaxCount() throws {
        let customSchedule = ResurfacingSchedule(
            intervals: [3600],
            maxResurfaceCount: 1,
            maxDailyNotifications: 3,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )
        let (note0, _) = try makeNote(resurfaceCount: 0)
        #expect(service.shouldResurface(note: note0, schedule: customSchedule) == true)

        let (note1, _) = try makeNote(resurfaceCount: 1)
        #expect(service.shouldResurface(note: note1, schedule: customSchedule) == false)
    }

    @Test("computeNextResurfaceDate with custom 1-hour interval")
    func customIntervalOneHour() throws {
        let customSchedule = ResurfacingSchedule(
            intervals: [3600],
            maxResurfaceCount: 1,
            maxDailyNotifications: 3,
            quietHoursStart: 22,
            quietHoursEnd: 8
        )

        // Create note at noon so quiet hours don't interfere
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 10
        components.hour = 12
        components.minute = 0
        let createdAt = Calendar.current.date(from: components)!

        let (note, _) = try makeNote(resurfaceCount: 0, createdAt: createdAt)
        let result = service.computeNextResurfaceDate(for: note, schedule: customSchedule)
        #expect(result != nil)
        let diff = result!.timeIntervalSince(createdAt)
        #expect(diff >= 3600)
        #expect(diff <= 3600 + 60) // Within a minute tolerance
    }
}
