import UIKit
import Social
import UniformTypeIdentifiers
import FlashNoteCore

final class ShareViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        handleSharedContent()
    }

    private func handleSharedContent() {
        // Capture extensionContext immediately — it can become nil if the
        // extension is terminated while our async Task is still running.
        guard let context = extensionContext,
              let extensionItems = context.inputItems as? [NSExtensionItem] else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }

        Task {
            var capturedText = ""

            for item in extensionItems {
                guard let attachments = item.attachments else { continue }

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        do {
                            if let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                                capturedText += url.absoluteString
                            }
                        } catch {
                            FNLog.share.error("Failed to load URL attachment: \(error)")
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        do {
                            if let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                                capturedText += text
                            }
                        } catch {
                            FNLog.share.error("Failed to load text attachment: \(error)")
                        }
                    }
                }
            }

            let trimmed = capturedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                context.completeRequest(returningItems: nil)
                return
            }

            do {
                let entry = BufferEntry(text: trimmed, source: .share)
                let buffer = FileBasedHotCaptureBuffer()
                try buffer.append(entry)
                FNLog.share.info("Shared content saved to buffer: \(entry.id)")

                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                FNLog.share.error("Failed to save shared content: \(error)")
            }

            context.completeRequest(returningItems: nil)
        }
    }
}
