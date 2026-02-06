import SwiftUI
import SwiftData
import FlashNoteCore

struct WatchCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var capturedText = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Tap to Capture")
                    .font(.system(.headline, design: .rounded))

                if showConfirmation {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .onTapGesture {
                presentDictation()
            }
            .navigationTitle("Capture")
        }
    }

    private func presentDictation() {
        // watchOS dictation is handled via system text input
        // Using WKExtension to present dictation controller
        #if os(watchOS)
        let device = WKInterfaceDevice.current()
        device.play(.click)
        #endif

        // On watchOS, we use the system dictation by presenting a text field
        // The actual dictation UI is provided by the system
    }

    private func saveNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = Note(text: trimmed, source: .watch)
        modelContext.insert(note)

        do {
            try modelContext.save()
            FNLog.watch.info("Watch note saved: \(note.id)")

            withAnimation {
                showConfirmation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showConfirmation = false
                }
            }
        } catch {
            FNLog.watch.error("Failed to save watch note: \(error)")
        }
    }
}
