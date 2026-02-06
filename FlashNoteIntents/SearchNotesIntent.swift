import AppIntents
import FlashNoteCore

struct SearchNotesIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Notes"
    static let description: IntentDescription = "Search your FlashNote notes."
    static let openAppWhenRun = true

    @Parameter(title: "Search Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$query)")
    }

    func perform() async throws -> some IntentResult {
        // Opens the app — the search query will be passed via the URL
        .result()
    }
}
