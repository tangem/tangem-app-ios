//
//  SendDestinationTextViewInput.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SendDestinationTextView2: View {
    @Binding var text: String
    let placeholder: String

    @State private var height: CGFloat = 10
    @State private var width: CGFloat = 10

    var body: some View {
        ZStack(alignment: .leading) {
            CustomTextView(text: $text, height: $height, width: $width, textFont: UIFont.preferredFont(forTextStyle: .body), textColor: .textPrimary1)

            if text.isEmpty {
                Text(placeholder)
                    .style(Fonts.Regular.body, color: Colors.Text.disabled)
            }
        }
        .readGeometry(\.size.width, bindTo: $width)
        .frame(minHeight: height, maxHeight: height)
        .border(.red.opacity(0.5))
        .overlay(alignment: .topLeading) {
            Text("\(height)")
                .font(.footnote)
                .foregroundColor(.red)
        }
        .onAppear {
            print("ZZZ on appear")
            let t = text
            text = t
            text = " "
            text = t
        }
    }
}

private struct CustomTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var width: CGFloat

    let textFont: UIFont
    let textColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        textView.autocapitalizationType = .none
        textView.keyboardType = .asciiCapable
        textView.autocorrectionType = .no
        textView.backgroundColor = .clear

        textView.textContainer.lineFragmentPadding = 0

//        textView.attributedText = attributedText(text)
//        textView.textColor = textColor
//        updateHeight(textView)

//        self.textView = textView

        print("ZZZ make view")

        return textView
    }

    func updateHeight() {
//        if let textView {
//            updateHeight(textView)
//        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        print("ZZZ update view")
        uiView.attributedText = attributedText(text)
        uiView.textColor = textColor
        updateHeight(uiView)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    private func updateHeight(_ uiView: UITextView) {
        let size = uiView.sizeThatFits(CGSize(width: width, height: .infinity))
        print("ZZZ new size", text, width, size)
        DispatchQueue.main.async {
            height = size.height
        }
    }

    private func attributedText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: textFont,
        ]

        return NSAttributedString(string: text, attributes: attributes)
    }
}

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
