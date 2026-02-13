import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor @Observable
final class InboxViewModel {
    var searchText = ""
    var searchResults: [Note] = []
    var isSearching = false

    private let searchService = LocalNoteSearchService()

    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func search(in context: ModelContext) {
        guard isSearchActive else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        do {
            searchResults = try searchService.search(query: searchText, in: context)
        } catch {
            FNLog.search.error("Search failed: \(error)")
            searchResults = []
        }
        isSearching = false
    }

    func deleteNote(_ note: Note, context: ModelContext) {
        note.status = .deleted
        note.updatedAt = .now
        SpotlightIndexer.remove(noteID: note.id)
        ResurfacingScheduler.cancelResurfacing(for: note.id)

        if let audioFileName = note.audioFileName {
            AppGroupContainer.deleteAudioFile(named: audioFileName)
        }

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Failed to delete note: \(error)")
        }
    }

    func togglePin(_ note: Note, context: ModelContext) {
        note.togglePin()

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Failed to toggle pin: \(error)")
        }
    }

    func archiveNote(_ note: Note, context: ModelContext) {
        note.status = .archived
        note.updatedAt = .now
        note.isTriaged = true
        ResurfacingScheduler.cancelResurfacing(for: note.id)

        do {
            try context.save()
        } catch {
            FNLog.capture.error("Failed to archive note: \(error)")
        }
    }
}
