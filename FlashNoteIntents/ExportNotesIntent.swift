import AppIntents
import FlashNoteCore

struct ExportNotesIntent: AppIntent {
    static let title: LocalizedStringResource = "Export Notes"
    static let description: IntentDescription = "Export your FlashNote notes."
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
