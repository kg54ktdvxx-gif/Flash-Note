import Foundation
import Testing
import SwiftData
@testable import FlashNoteCore

@Suite("CaptureStreakService")
struct CaptureStreakServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func insertNote(
        _ text: String,
        daysAgo: Int,
        status: NoteStatus = .active,
        in context: ModelContext
    ) {
        let note = Note(text: text)
        note.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        note.status = status
        context.insert(note)
    }

    @Test("empty database returns 0")
    @MainActor
    func emptyDatabase() throws {
        let context = try makeContext()
        #expect(CaptureStreakService.currentStreak(in: context) == 0)
    }

    @Test("one note today returns 1")
    @MainActor
    func oneNoteToday() throws {
        let context = try makeContext()
        insertNote("today", daysAgo: 0, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 1)
    }

    @Test("notes today and yesterday returns 2")
    @MainActor
    func todayAndYesterday() throws {
        let context = try makeContext()
        insertNote("today", daysAgo: 0, in: context)
        insertNote("yesterday", daysAgo: 1, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 2)
    }

    @Test("three consecutive days returns 3")
    @MainActor
    func threeConsecutiveDays() throws {
        let context = try makeContext()
        insertNote("today", daysAgo: 0, in: context)
        insertNote("yesterday", daysAgo: 1, in: context)
        insertNote("two days ago", daysAgo: 2, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 3)
    }

    @Test("gap breaks streak — today + 2 days ago returns 1")
    @MainActor
    func gapBreaksStreak() throws {
        let context = try makeContext()
        insertNote("today", daysAgo: 0, in: context)
        insertNote("two days ago", daysAgo: 2, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 1)
    }

    @Test("no note today returns 0 even with past notes")
    @MainActor
    func noNoteToday() throws {
        let context = try makeContext()
        insertNote("yesterday", daysAgo: 1, in: context)
        insertNote("two days ago", daysAgo: 2, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 0)
    }

    @Test("multiple notes on same day count as one day")
    @MainActor
    func multipleNotesOnSameDay() throws {
        let context = try makeContext()
        insertNote("first today", daysAgo: 0, in: context)
        insertNote("second today", daysAgo: 0, in: context)
        insertNote("third today", daysAgo: 0, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 1)
    }

    @Test("deleted notes are excluded from streak")
    @MainActor
    func deletedNotesExcluded() throws {
        let context = try makeContext()
        insertNote("deleted today", daysAgo: 0, status: .deleted, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 0)
    }

    @Test("archived notes still count toward streak")
    @MainActor
    func archivedNotesCounted() throws {
        let context = try makeContext()
        insertNote("archived today", daysAgo: 0, status: .archived, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 1)
    }

    @Test("task notes count toward streak")
    @MainActor
    func taskNotesCounted() throws {
        let context = try makeContext()
        insertNote("task today", daysAgo: 0, status: .task, in: context)
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 1)
    }

    @Test("long streak of 7 consecutive days")
    @MainActor
    func longStreak() throws {
        let context = try makeContext()
        for day in 0..<7 {
            insertNote("day \(day)", daysAgo: day, in: context)
        }
        try context.save()

        #expect(CaptureStreakService.currentStreak(in: context) == 7)
    }
}
