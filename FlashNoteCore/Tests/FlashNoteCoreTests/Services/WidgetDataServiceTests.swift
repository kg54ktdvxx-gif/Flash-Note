import Foundation
import Testing
import SwiftData
@testable import FlashNoteCore

private struct WidgetItem: Codable {
    let id: UUID
    let text: String
    let timeAgo: String
}

@Suite("WidgetDataService")
struct WidgetDataServiceTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("updates shared defaults with recent notes")
    @MainActor
    func updatesSharedDefaults() throws {
        let context = try makeContext()
        let note = Note(text: "Test note")
        context.insert(note)
        try context.save()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")
        #expect(data != nil)
    }

    @Test("limits to 5 recent notes")
    @MainActor
    func limitsToFive() throws {
        let context = try makeContext()
        for i in 0..<10 {
            let note = Note(text: "Note \(i)")
            context.insert(note)
        }
        try context.save()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")!
        let items = try JSONDecoder().decode([WidgetItem].self, from: data)
        #expect(items.count == 5)
    }

    @Test("excludes deleted notes")
    @MainActor
    func excludesDeleted() throws {
        let context = try makeContext()
        let active = Note(text: "Active note")
        context.insert(active)
        let deleted = Note(text: "Deleted note")
        deleted.status = .deleted
        context.insert(deleted)
        try context.save()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")!
        let items = try JSONDecoder().decode([WidgetItem].self, from: data)
        #expect(items.count == 1)
        #expect(items[0].text == "Active note")
    }

    @Test("excludes archived notes")
    @MainActor
    func excludesArchived() throws {
        let context = try makeContext()
        let active = Note(text: "Active note")
        context.insert(active)
        let archived = Note(text: "Archived note")
        archived.status = .archived
        context.insert(archived)
        try context.save()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")!
        let items = try JSONDecoder().decode([WidgetItem].self, from: data)
        #expect(items.count == 1)
        #expect(items[0].text == "Active note")
    }

    @Test("handles empty database")
    @MainActor
    func handlesEmpty() throws {
        let context = try makeContext()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")!
        let items = try JSONDecoder().decode([WidgetItem].self, from: data)
        #expect(items.isEmpty)
    }

    @Test("truncates note text to 80 characters")
    @MainActor
    func truncatesText() throws {
        let context = try makeContext()
        let longText = String(repeating: "a", count: 200)
        let note = Note(text: longText)
        context.insert(note)
        try context.save()

        WidgetDataService.updateRecentNotes(context: context)

        let data = AppGroupContainer.sharedDefaults.data(forKey: "recentNotes")!
        let items = try JSONDecoder().decode([WidgetItem].self, from: data)
        #expect(items[0].text.count == 80)
    }
}
