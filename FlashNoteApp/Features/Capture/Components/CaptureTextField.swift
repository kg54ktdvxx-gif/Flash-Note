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
        textView.textColor = .label

        // Placeholder setup
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
        }

        if autoFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                textView.becomeFirstResponder()
            }
        }

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if text.isEmpty && !textView.isFirstResponder {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else if textView.textColor == .placeholderText && !text.isEmpty {
            textView.text = text
            textView.textColor = .label
        } else if textView.text != text && textView.textColor != .placeholderText {
            textView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: CaptureTextField

        init(_ parent: CaptureTextField) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .label
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

private extension UIFont {
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
