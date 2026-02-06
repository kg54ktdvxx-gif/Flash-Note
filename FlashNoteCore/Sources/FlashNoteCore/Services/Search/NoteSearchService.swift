import Foundation
import SwiftData

public protocol NoteSearchService: Sendable {
    @MainActor
    func search(query: String, in context: ModelContext) throws -> [Note]
}

public struct LocalNoteSearchService: NoteSearchService, Sendable {
    public init() {}

    @MainActor
    public func search(query: String, in context: ModelContext) throws -> [Note] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        let predicate = #Predicate<Note> { note in
            note.text.localizedStandardContains(trimmed) &&
            note.statusRaw != "deleted"
        }

        var descriptor = FetchDescriptor<Note>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 50

        return try context.fetch(descriptor)
    }
}
