//
//  TangemPayOrderCardTextField.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

/// Backed by UIKit for the two hooks SwiftUI does not expose: handing first responder to the next field
/// without the keyboard dropping, and masking input while keeping the caret where the user left it.
struct TangemPayOrderCardTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focusedField: TangemPayOrderCardDataField.ID?

    let field: TangemPayOrderCardDataField
    let mask: TangemPayInputMask?
    let nextFieldID: TangemPayOrderCardDataField.ID?
    let textColor: Color

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.delegate = context.coordinator
        textField.accessibilityLabel = field.title
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange),
            for: .editingChanged
        )

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        let font = DesignSystem.Font.bodyMediumToken.uiFont

        if uiView.font != font {
            uiView.font = font
        }

        uiView.textColor = UIColor(textColor)
        uiView.tintColor = UIColor(DesignSystem.Color.iconBrand)

        // Every keystroke republishes the form, so all eleven fields run this. Re-assigning input traits on
        // the field that currently holds the keyboard makes it reload, so only write what actually changed.
        if uiView.attributedPlaceholder?.string != mask?.placeholder {
            uiView.attributedPlaceholder = mask.map {
                NSAttributedString(
                    string: $0.placeholder,
                    attributes: [.foregroundColor: UIColor(DesignSystem.Color.textTertiary)]
                )
            }
        }

        if uiView.keyboardType != field.keyboardType {
            uiView.keyboardType = field.keyboardType
        }

        if uiView.textContentType != field.textContentType {
            uiView.textContentType = field.textContentType
        }

        if uiView.isEnabled != field.isEditable {
            uiView.isEnabled = field.isEditable
        }

        let returnKeyType: UIReturnKeyType = nextFieldID == nil ? .done : .next

        if uiView.returnKeyType != returnKeyType {
            uiView.returnKeyType = returnKeyType
        }

        syncFirstResponder(uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func syncFirstResponder(_ uiView: UITextField) {
        let shouldFocus = focusedField == field.id

        // Resigning only once nothing is focused at all is what keeps the keyboard up: when focus moves
        // between fields the outgoing one has to hold first responder until the incoming one takes it.
        guard shouldFocus || focusedField == nil, shouldFocus != uiView.isFirstResponder else { return }

        DispatchQueue.main.async {
            // Re-read rather than reuse the value above: the teardown in `textFieldDidEndEditing` is deferred
            // too, so focus can move between scheduling this and running it.
            let shouldFocus = focusedField == field.id

            if shouldFocus, !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !shouldFocus, uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
}

// MARK: - Coordinator

extension TangemPayOrderCardTextField {
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: TangemPayOrderCardTextField

        init(parent: TangemPayOrderCardTextField) {
            self.parent = parent
        }

        @objc
        func textDidChange(_ textField: UITextField) {
            update(text: textField.text ?? "")
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.focusedField != parent.field.id {
                parent.focusedField = parent.field.id
            }

            pinPrefix(in: textField)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // UIKit ends editing from inside a SwiftUI layout pass, so writing the bindings here directly is
            // a "modifying state during view update" cycle. By the time this runs a field taking focus over
            // has already claimed it, and the guard below leaves it alone.
            DispatchQueue.main.async { [self] in
                unpinPrefix(in: textField)

                if parent.focusedField == parent.field.id {
                    parent.focusedField = nil
                }
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            if let nextFieldID = parent.nextFieldID {
                parent.focusedField = nextFieldID
            } else {
                parent.focusedField = nil
                textField.resignFirstResponder()
            }

            // `false` also suppresses the implicit `editingDidEndOnExit` dismissal.
            return false
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            guard let mask = parent.mask, textField.markedTextRange == nil else {
                return true
            }

            let current = (textField.text ?? "") as NSString
            var editRange = range

            // Backspacing onto a separator would otherwise cost a keystroke for nothing: the mask puts the
            // separator straight back, leaving the text as it was. Take the digit in front of it as well.
            if string.isEmpty, range.length == 1, range.location > 0,
               let deleted = current.substring(with: range).first, !deleted.isWholeNumber {
                editRange = NSRange(location: range.location - 1, length: 2)
            }

            let updated = current.replacingCharacters(in: editRange, with: string) as NSString
            let caretIndex = min(editRange.location + string.count, updated.length)
            let digitsBeforeCaret = mask.digitCount(in: updated.substring(to: caretIndex))
            let masked = mask.apply(to: updated as String)

            textField.text = masked
            update(text: masked)

            // A paste hands the field a fresh selection right after ours, so the caret has to be set again
            // once that has happened.
            let isPaste = string.count > 1
            moveCaret(after: digitsBeforeCaret, in: textField, mask: mask, deferred: isPaste)

            return false
        }

        private func pinPrefix(in textField: UITextField) {
            guard let mask = parent.mask, textField.text?.isEmpty ?? true else { return }

            textField.text = mask.prefix
            update(text: mask.prefix)
            moveCaret(after: 0, in: textField, mask: mask, deferred: false)
        }

        private func unpinPrefix(in textField: UITextField) {
            guard let mask = parent.mask, textField.text == mask.prefix else { return }

            textField.text = ""
            update(text: "")
        }

        private func update(text: String) {
            if parent.text != text {
                parent.text = text
            }
        }

        private func moveCaret(
            after digits: Int,
            in textField: UITextField,
            mask: TangemPayInputMask,
            deferred: Bool
        ) {
            let offset = mask.offset(afterDigits: digits, in: textField.text ?? "")

            let place = {
                guard let position = textField.position(from: textField.beginningOfDocument, offset: offset) else {
                    return
                }

                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }

            if deferred {
                DispatchQueue.main.async(execute: place)
            } else {
                place()
            }
        }
    }
}
