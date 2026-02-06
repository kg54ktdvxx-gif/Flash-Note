import AppIntents

struct FlashNoteShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureNoteIntent(),
            phrases: [
                "Capture a thought in \(.applicationName)",
                "Save a note in \(.applicationName)",
                "Jot something down in \(.applicationName)",
                "Quick note in \(.applicationName)"
            ],
            shortTitle: "Capture Thought",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: SearchNotesIntent(),
            phrases: [
                "Search notes in \(.applicationName)",
                "Find a note in \(.applicationName)"
            ],
            shortTitle: "Search Notes",
            systemImageName: "magnifyingglass"
        )
    }
}
