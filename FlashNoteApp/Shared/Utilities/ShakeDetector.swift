import UIKit

extension Notification.Name {
    static let deviceShaken = Notification.Name("deviceShaken")
    static let focusCaptureTextField = Notification.Name("focusCaptureTextField")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        if motion == .motionShake {
            guard UserDefaults.standard.object(forKey: "shakeEnabled") as? Bool ?? true else { return }
            NotificationCenter.default.post(name: .deviceShaken, object: nil)
        }
    }
}
