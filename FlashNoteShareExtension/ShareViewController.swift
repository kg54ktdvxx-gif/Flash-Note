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
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }

        Task {
            var capturedText = ""

            for item in extensionItems {
                guard let attachments = item.attachments else { continue }

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                        if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                            capturedText += url.absoluteString
                        }
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                        if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                            capturedText += text
                        }
                    }
                }
            }

            let trimmed = capturedText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                completeRequest()
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

            completeRequest()
        }
    }

    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
