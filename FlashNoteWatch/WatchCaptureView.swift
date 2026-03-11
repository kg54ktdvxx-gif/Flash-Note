import SwiftUI
import SwiftData
import FlashNoteCore

struct WatchCaptureView: View {
    @State private var showConfirmation = false
    @State private var showTextInput = false
    @State private var confirmationTask: Task<Void, Never>?

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
                showTextInput = true
            }
            .sheet(isPresented: $showTextInput) {
                WatchTextInputView { text in
                    saveNote(text)
                }
            }
            .onDisappear {
                confirmationTask?.cancel()
            }
            .navigationTitle("Capture")
        }
    }

    private func saveNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // C3 fix: Only send to iPhone via WatchConnectivity — iPhone is the single
        // source of truth. Previously we also saved to Watch SwiftData, creating
        // duplicates when the iPhone buffer was flushed.
        WatchConnectivityManager.shared.sendNote(text: trimmed)
        FNLog.watch.info("Watch note sent to iPhone")

        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #endif

        withAnimation {
            showConfirmation = true
        }

        confirmationTask?.cancel()
        confirmationTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation {
                showConfirmation = false
            }
        }
    }
}

/// Minimal text-input sheet that presents the watchOS dictation/scribble keyboard.
private struct WatchTextInputView: View {
    var onSave: (String) -> Void
    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            TextField("Speak or type...", text: $text)
                .font(.system(.body, design: .rounded))

            Button("Save") {
                onSave(text)
                dismiss()
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
