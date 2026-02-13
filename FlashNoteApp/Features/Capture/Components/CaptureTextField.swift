import SwiftUI
import UIKit

struct CaptureTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "What's on your mind?"
    var onSubmit: (() -> Void)?
    var autoFocus: Bool = true

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        // Editorial serif font for the writing surface
        let baseFont = UIFont.preferredFont(forTextStyle: .title3)
        textView.font = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .regular).withSerif()

        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.returnKeyType = .default
        textView.tintColor = UIColor(AppColors.accent)

        // Adaptive text color
        textView.textColor = UIColor.label
        textView.keyboardAppearance = .default

        // Keyboard toolbar with Done button
        textView.inputAccessoryView = makeKeyboardToolbar(coordinator: context.coordinator)

        // Placeholder setup
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = Self.placeholderColor
        } else {
            textView.text = text
        }

        context.coordinator.textView = textView

        if autoFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                textView.becomeFirstResponder()
            }
        }

        return textView
    }

    private func makeKeyboardToolbar(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 36))
        toolbar.barStyle = .default

        // Transparent, minimal styling
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .prominent,
            target: coordinator,
            action: #selector(Coordinator.dismissKeyboard)
        )
        doneButton.setTitleTextAttributes([
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        ], for: .normal)

        toolbar.items = [spacer, doneButton]
        return toolbar
    }

    private static let placeholderColor = UIColor.tertiaryLabel

    func updateUIView(_ textView: UITextView, context: Context) {
        // Skip if this update was triggered by our own delegate callback
        guard !context.coordinator.isUpdating else { return }

        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }

        if text.isEmpty && !textView.isFirstResponder {
            textView.text = placeholder
            textView.textColor = Self.placeholderColor
        } else if textView.textColor == Self.placeholderColor && !text.isEmpty {
            textView.text = text
            textView.textColor = .label
        } else if textView.text != text && textView.textColor != Self.placeholderColor {
            textView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, placeholder: placeholder)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var placeholder: String
        var isUpdating = false
        weak var textView: UITextView?
        private nonisolated(unsafe) var focusObserver: (any NSObjectProtocol)?

        init(text: Binding<String>, placeholder: String) {
            self.text = text
            self.placeholder = placeholder
            super.init()
            focusObserver = NotificationCenter.default.addObserver(
                forName: .focusCaptureTextField,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.textView?.becomeFirstResponder()
            }
        }

        deinit {
            if let focusObserver {
                NotificationCenter.default.removeObserver(focusObserver)
            }
        }

        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == CaptureTextField.placeholderColor {
                textView.text = ""
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = CaptureTextField.placeholderColor
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            text.wrappedValue = textView.text
            isUpdating = false
        }
    }
}

private extension UIFont {
    func withSerif() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.serif) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
