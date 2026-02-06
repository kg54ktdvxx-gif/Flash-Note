import WatchConnectivity
import FlashNoteCore

final class WatchConnectivityManager: NSObject, WCSessionDelegate, Sendable {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        FNLog.watch.info("WCSession activated")
    }

    // MARK: - Send note from Watch to iPhone

    func sendNote(text: String) {
        guard WCSession.default.isReachable else {
            // Fall back to transferUserInfo for background delivery
            WCSession.default.transferUserInfo([
                "type": "newNote",
                "text": text,
                "source": CaptureSource.watch.rawValue,
                "timestamp": Date.now.timeIntervalSince1970
            ])
            return
        }

        WCSession.default.sendMessage([
            "type": "newNote",
            "text": text,
            "source": CaptureSource.watch.rawValue
        ], replyHandler: nil) { error in
            FNLog.watch.error("Failed to send note: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error {
            FNLog.watch.error("WCSession activation failed: \(error)")
        } else {
            FNLog.watch.info("WCSession state: \(activationState.rawValue)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleReceivedMessage(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleReceivedMessage(userInfo)
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String, type == "newNote",
              let text = message["text"] as? String else { return }

        let sourceRaw = message["source"] as? String ?? CaptureSource.watch.rawValue
        let source = CaptureSource(rawValue: sourceRaw) ?? .watch

        let entry = BufferEntry(text: text, source: source)
        let buffer = FileBasedHotCaptureBuffer()

        do {
            try buffer.append(entry)
            FNLog.watch.info("Received note from Watch: \(entry.id)")
        } catch {
            FNLog.watch.error("Failed to buffer Watch note: \(error)")
        }
    }
}
