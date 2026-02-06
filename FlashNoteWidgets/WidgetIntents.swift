import AppIntents

struct OpenCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Capture"
    static let description: IntentDescription = "Opens the FlashNote capture screen."
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenInboxIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Inbox"
    static let description: IntentDescription = "Opens the FlashNote inbox."
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
