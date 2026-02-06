import AppIntents
import FlashNoteCore

struct CaptureNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture a Note"
    static let description: IntentDescription = "Quickly save a thought to FlashNote."

    @Parameter(title: "Thought")
    var thought: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$thought)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = thought.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw $thought.needsValueError("What would you like to capture?")
        }

        let entry = BufferEntry(text: trimmed, source: .siri)
        let buffer = FileBasedHotCaptureBuffer()
        do {
            try buffer.append(entry)
        } catch {
            FNLog.intent.error("Siri capture failed: \(error)")
            return .result(dialog: "Sorry, I couldn't save that thought. Please try again.")
        }

        FNLog.intent.info("Siri captured note: \(entry.id)")

        return .result(dialog: "Got it! I saved your thought.")
    }
}
