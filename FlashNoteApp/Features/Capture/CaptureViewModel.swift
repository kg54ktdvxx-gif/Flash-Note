import SwiftUI
import SwiftData
import FlashNoteCore

@MainActor @Observable
final class CaptureViewModel {
    var text = ""
    var showSaveConfirmation = false
    var isVoiceMode = false

    // Task suggestion (Feature 7)
    var showTaskSuggestion = false
    private var lastSavedNote: Note?

    // Merge prompt (Feature 10)
    var showMergePrompt = false
    private var mergeCurrentNote: Note?
    private var mergePreviousNote: Note?

    // Auto-draft (Feature 5)
    private static let draftKey = "capture_draft"
    private var draftSaveTask: Task<Void, Never>?

    private let hapticService: HapticService

    init(hapticService: HapticService = DependencyContainer.shared.hapticService) {
        self.hapticService = hapticService
        // Restore draft on init
        if let draft = UserDefaults.standard.string(forKey: Self.draftKey), !draft.isEmpty {
            self.text = draft
        }
    }

    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Draft persistence (Feature 5)

    func scheduleDraftSave() {
        draftSaveTask?.cancel()
        draftSaveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            saveDraft()
        }
    }

    func saveDraft() {
        let current = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.draftKey)
        } else {
            UserDefaults.standard.set(text, forKey: Self.draftKey)
        }
    }

    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    // MARK: - Save

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

            hapticService.noteSaved()
            withAnimation(.spring(duration: 0.4)) {
                showSaveConfirmation = true
            }
            text = ""
            clearDraft()

            // Post-save: task detection (Feature 7)
            if TaskDetectionService.looksLikeTask(trimmed) {
                lastSavedNote = note
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(duration: 0.3)) {
                        showTaskSuggestion = true
                    }
                }
            }

            // Post-save: merge check (Feature 10)
            checkForMerge(currentNote: note, context: context)
        } catch {
            FNLog.capture.error("Failed to save note: \(error)")
            context.delete(note)
        }
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

            hapticService.noteSaved()
            withAnimation(.spring(duration: 0.4)) {
                showSaveConfirmation = true
            }
        } catch {
            FNLog.capture.error("Failed to save voice note: \(error)")
            context.delete(note)
        }
    }

    func handlePrefill(_ prefillText: String?) {
        guard let prefillText, !prefillText.isEmpty else { return }
        text = prefillText
    }

    // MARK: - Task suggestion (Feature 7)

    func markAsTask(context: ModelContext) {
        guard let note = lastSavedNote else { return }
        note.isTask = true
        note.status = .task
        note.updatedAt = .now

        do {
            try context.save()
            FNLog.capture.info("Note marked as task: \(note.id)")
        } catch {
            FNLog.capture.error("Failed to mark as task: \(error)")
        }
        lastSavedNote = nil
    }

    // MARK: - Merge (Feature 10)

    private func checkForMerge(currentNote: Note, context: ModelContext) {
        var descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { $0.statusRaw != "deleted" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 2

        guard let recent = try? context.fetch(descriptor),
              recent.count >= 2 else { return }

        let previous = recent[1]
        let timeDiff = currentNote.createdAt.timeIntervalSince(previous.createdAt)

        guard timeDiff < 120 else { return }

        mergeCurrentNote = currentNote
        mergePreviousNote = previous

        // Delay merge prompt — if task suggestion is showing, wait for it
        let delay: Duration = showTaskSuggestion ? .seconds(4.5) : .seconds(1.5)
        Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.3)) {
                showMergePrompt = true
            }
        }
    }

    func mergeWithPrevious(context: ModelContext) {
        guard let current = mergeCurrentNote, let previous = mergePreviousNote else { return }
        previous.text += "\n\n" + current.text
        previous.updatedAt = .now

        // Clean up the current note
        current.status = .deleted
        current.updatedAt = .now
        SpotlightIndexer.remove(noteID: current.id)
        ResurfacingScheduler.cancelResurfacing(for: current.id)

        do {
            try context.save()
            FNLog.capture.info("Merged note \(current.id) into \(previous.id)")
        } catch {
            FNLog.capture.error("Failed to merge notes: \(error)")
        }

        mergeCurrentNote = nil
        mergePreviousNote = nil
    }

    func dismissMerge() {
        mergeCurrentNote = nil
        mergePreviousNote = nil
    }
}
