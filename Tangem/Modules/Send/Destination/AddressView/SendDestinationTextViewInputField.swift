//
//  SendDestinationTextViewInputField.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - SwiftUI view

struct SendDestinationTextViewInputField: View {
    @ObservedObject var heightModel: SendDestinationTextViewInputFieldModel

    @Binding var text: String
    let placeholder: String

    let font: UIFont
    let color: UIColor

    @State private var showPlaceholder = false
    @State private var width: CGFloat = 10

    var body: some View {
        ZStack(alignment: .leading) {
            if showPlaceholder {
                Text(placeholder)
                    .style(Fonts.Regular.body, color: Colors.Text.disabled)
            }

            CustomTextView(
                text: $text,
                showPlaceholder: $showPlaceholder,
                currentHeight: $heightModel.height,
                width: $width,
                font: font,
                color: color
            )
        }
        .readGeometry(\.size.width, bindTo: $width)
        .frame(minHeight: heightModel.height, maxHeight: heightModel.height)
    }
}

// MARK: - SwiftUI wrapper of UITextView

private struct CustomTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var showPlaceholder: Bool
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

        textView.attributedText = attributedText(text)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let newAttributedText = attributedText(text)

        DispatchQueue.main.async {
            uiView.attributedText = newAttributedText
            uiView.textColor = color

            showPlaceholder = text.isEmpty

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

private extension CustomTextView {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextView

        init(parent: CustomTextView) {
            self.parent = parent
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
