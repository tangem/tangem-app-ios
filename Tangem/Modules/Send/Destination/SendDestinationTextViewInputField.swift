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

// MARK: - State model

import Combine

class SendDestinationTextViewHeightModel: ObservableObject {
    @Published var height: CGFloat = 10

    var bag: Set<AnyCancellable> = []

    init() {
        print("ZZZ [text model] init")

        $height
            .sink { height in
                print("ZZZ [text model] height changed \(height)")
            }
            .store(in: &bag)
    }
}

// MARK: - SwiftUI view

struct SendDestinationTextViewInputField: View {
    @ObservedObject var heightModel: SendDestinationTextViewHeightModel

    @Binding var text: String
    let placeholder: String

    let font: UIFont
    let color: UIColor

    @State private var showPlaceholder = false
//    [REDACTED_USERNAME] private var currentHeight: CGFloat = 10
    @State private var width: CGFloat = 10

    var body: some View {
        ZStack(alignment: .leading) {
            CustomTextView(
                text: $text,
                showPlaceholder: $showPlaceholder,
                currentHeight: $heightModel.height,
                width: $width,
                font: font,
                color: color
            )

            if showPlaceholder {
                Text(placeholder)
                    .style(Fonts.Regular.body, color: Colors.Text.disabled)
            }
        }
        .readGeometry(\.size.width, bindTo: $width)
        .frame(minHeight: heightModel.height, maxHeight: heightModel.height)
        .overlay(alignment: .topTrailing) {
            Text("\(width) x \(heightModel.height)")
                .font(.caption2)
                .foregroundStyle(.red)
        }
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
        print("ZZZ make view")
        let textView = UITextView()
        textView.delegate = context.coordinator

        textView.autocapitalizationType = .none
        textView.keyboardType = .asciiCapable
        textView.autocorrectionType = .no
        textView.backgroundColor = .clear

        textView.textContainer.lineFragmentPadding = 0

        textView.attributedText = attributedText(text)

        let size = textView.sizeThatFits(CGSize(width: width, height: .infinity))
        print("ZZZ [make view] text \(text), width \(width), height \(size.height)")
        print("ZZZ [make view] current height \(currentHeight)")
        print("ZZZ [make view] separate calculation of text size: \(text.height(forContainerWidth: width, font: font)), \(attributedText(text).height(withConstrainedWidth: width)) ")

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let newAttributedText = attributedText(text)

        DispatchQueue.main.async {
            uiView.attributedText = newAttributedText
            uiView.textColor = color

            showPlaceholder = text.isEmpty

            let size = uiView.sizeThatFits(CGSize(width: width, height: .infinity))
            print("ZZZ [update view] text \(text), width \(width), height \(size.height)")
            print("ZZZ [update view] current height \(currentHeight)")
            print("ZZZ [update view] separate calculation of text size: \(text.height(forContainerWidth: width, font: font)), \(attributedText(text).height(withConstrainedWidth: width)) ")
            if currentHeight != size.height {
                currentHeight = size.height
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    private func updateHeight(_ uiView: UITextView) {
        let size = uiView.sizeThatFits(CGSize(width: width, height: .infinity))
        DispatchQueue.main.async {
            currentHeight = size.height
        }
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

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return ceil(boundingBox.width)
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = (self as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = (self as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}
