import CoreSpotlight
import FlashNoteCore

enum SpotlightIndexer {
    private static let domainIdentifier = "com.flashnote.notes"

    static func index(note: Note) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = String(note.text.prefix(60))
        attributeSet.contentDescription = note.text
        attributeSet.contentCreationDate = note.createdAt
        attributeSet.contentModificationDate = note.updatedAt

        let item = CSSearchableItem(
            uniqueIdentifier: note.id.uuidString,
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error {
                FNLog.spotlight.error("Index failed: \(error)")
            }
        }
    }

    static func remove(noteID: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: [noteID.uuidString]
        ) { error in
            if let error {
                FNLog.spotlight.error("Remove failed: \(error)")
            }
        }
    }

    static func removeAll() {
        CSSearchableIndex.default().deleteSearchableItems(
            withDomainIdentifiers: [domainIdentifier]
        ) { error in
            if let error {
                FNLog.spotlight.error("Remove all failed: \(error)")
            }
        }
    }
}
