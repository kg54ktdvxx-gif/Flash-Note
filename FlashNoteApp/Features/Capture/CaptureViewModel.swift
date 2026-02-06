import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor @Observable
final class CaptureViewModel {
    var text = ""
    var showSaveConfirmation = false
    var isVoiceMode = false

    private let hapticService: HapticService

    init(hapticService: HapticService = DependencyContainer.shared.hapticService) {
        self.hapticService = hapticService
    }

    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(context: ModelContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = Note(text: trimmed, source: .keyboard)
        context.insert(note)

        do {
            try context.save()
            SpotlightIndexer.index(note: note)
            ResurfacingScheduler.scheduleResurfacing(for: note)
            FNLog.capture.info("Note saved: \(note.id)")
        } catch {
            FNLog.capture.error("Failed to save note: \(error)")
        }

        hapticService.noteSaved()

        withAnimation(.spring(duration: 0.4)) {
            showSaveConfirmation = true
        }

        text = ""
    }

    func saveVoiceNote(
        text: String,
        audioFileName: String?,
        audioDuration: TimeInterval?,
        confidence: Float?,
        context: ModelContext
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let note = Note(
            text: trimmed,
            source: .voice,
            audioFileName: audioFileName,
            audioDuration: audioDuration,
            transcriptionConfidence: confidence
        )
        context.insert(note)

        do {
            try context.save()
            SpotlightIndexer.index(note: note)
            ResurfacingScheduler.scheduleResurfacing(for: note)
            FNLog.capture.info("Voice note saved: \(note.id)")
        } catch {
            FNLog.capture.error("Failed to save voice note: \(error)")
        }

        hapticService.noteSaved()

        withAnimation(.spring(duration: 0.4)) {
            showSaveConfirmation = true
        }
    }

    func handlePrefill(_ prefillText: String?) {
        guard let prefillText, !prefillText.isEmpty else { return }
        text = prefillText
    }
}
