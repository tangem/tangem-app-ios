//
//  TangemPayActivateCardDigitsField.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

/// Invisible — the digits are drawn on the card. It owns the keypad, so it has to hand first responder back
/// as well as take it, which is what `CustomTextField` cannot do.
struct TangemPayActivateCardDigitsField: UIViewRepresentable {
    @Binding var text: String

    let isFocused: Bool
    let maxCount: Int
    let accessibilityLabel: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        if uiView.accessibilityLabel != accessibilityLabel {
            uiView.accessibilityLabel = accessibilityLabel
        }

        syncFirstResponder(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func syncFirstResponder(_ uiView: UITextField) {
        guard isFocused != uiView.isFirstResponder else { return }

        DispatchQueue.main.async {
            if isFocused {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }
    }
}

// MARK: - Coordinator

extension TangemPayActivateCardDigitsField {
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TangemPayActivateCardDigitsField

        init(parent: TangemPayActivateCardDigitsField) {
            self.parent = parent
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let current = (textField.text ?? "") as NSString
            let updated = current.replacingCharacters(in: range, with: string)
            let digits = String(updated.filter(\.isWholeNumber).prefix(parent.maxCount))

            textField.text = digits

            if parent.text != digits {
                parent.text = digits
            }

            return false
        }
    }
}
