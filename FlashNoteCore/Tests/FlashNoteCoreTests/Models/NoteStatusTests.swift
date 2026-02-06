import Testing
@testable import FlashNoteCore

@Suite("NoteStatus")
struct NoteStatusTests {
    @Test("raw value round-trip for all cases")
    func rawValueRoundTrip() {
        for status in NoteStatus.allCases {
            let reconstructed = NoteStatus(rawValue: status.rawValue)
            #expect(reconstructed == status)
        }
    }

    @Test("raw values are stable strings")
    func stableRawValues() {
        #expect(NoteStatus.active.rawValue == "active")
        #expect(NoteStatus.archived.rawValue == "archived")
        #expect(NoteStatus.task.rawValue == "task")
        #expect(NoteStatus.deleted.rawValue == "deleted")
    }

    @Test("invalid raw value returns nil")
    func invalidRawValue() {
        #expect(NoteStatus(rawValue: "bogus") == nil)
        #expect(NoteStatus(rawValue: "") == nil)
    }
}
