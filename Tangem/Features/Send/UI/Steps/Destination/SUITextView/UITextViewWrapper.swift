//
//  UITextViewWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit
import TangemAccessibilityIdentifiers

struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var currentHeight: CGFloat
    @Binding var width: CGFloat

    let font: UIFont
    let color: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        textView.autocapitalizationType = .none
        textView.keyboardType = .asciiCapable
        textView.autocorrectionType = .no
        textView.backgroundColor = .clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero

        let newAttributedText = attributedText(text)
        // UITextView instance won't use attributes from an empty NSAttributedString, so we temporarily
        // assign a dummy non-empty attributed string to set all attributes in the UITextView instance
        if newAttributedText.string.isEmpty {
            textView.attributedText = attributedText(#fileID)
        }
        textView.attributedText = newAttributedText
        textView.accessibilityIdentifier = SendAccessibilityIdentifiers.addressTextView

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let newAttributedText = attributedText(text)

        // [REDACTED_USERNAME] members of the SwiftUI view cannot be updated synchronously
        DispatchQueue.main.async {
            if uiView.attributedText.string != newAttributedText.string {
                uiView.attributedText = newAttributedText
            }
            uiView.textColor = color

            let size = uiView.sizeThatFits(CGSize(width: width, height: .infinity))
            if currentHeight != size.height {
                currentHeight = size.height
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    private func attributedText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font,
        ]

        return NSAttributedString(string: text, attributes: attributes)
    }
}

// MARK: - Coordinator

extension UITextViewWrapper {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewWrapper

        init(parent: UITextViewWrapper) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // We always keep contentOffset is zero to avoid text jumping
            scrollView.contentOffset = .zero
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.endEditing(true)
                return false
            } else {
                return true
            }
        }
    }
}
