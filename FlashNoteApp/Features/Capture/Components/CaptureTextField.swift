import SwiftUI
import UIKit

struct CaptureTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "What's on your mind?"
    var font: UIFont = .preferredFont(forTextStyle: .title3)
    var onSubmit: (() -> Void)?
    var autoFocus: Bool = true

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(
            ofSize: font.pointSize,
            weight: .regular
        ).rounded()
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.returnKeyType = .default
        textView.textColor = .white
        textView.keyboardAppearance = .dark

        // Placeholder setup
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.white.withAlphaComponent(0.45)
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

    private static let placeholderColor = UIColor.white.withAlphaComponent(0.45)

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
            textView.textColor = .white
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

        private static let placeholderColor = UIColor.white.withAlphaComponent(0.45)

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == Self.placeholderColor {
                textView.text = ""
                textView.textColor = .white
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = placeholder
                textView.textColor = Self.placeholderColor
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
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
