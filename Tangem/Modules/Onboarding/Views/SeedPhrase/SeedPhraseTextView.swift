//
//  SeedPhraseTextView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct SeedPhraseTextView: UIViewRepresentable {
    private unowned var inputProcessor: SeedPhraseInputProcessor

    init(inputProcessor: SeedPhraseInputProcessor) {
        self.inputProcessor = inputProcessor
    }

    func makeUIView(context: UIViewRepresentableContext<SeedPhraseTextView>) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = nil
        textView.autocapitalizationType = .none
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = false
        textView.enablesReturnKeyAutomatically = false
        textView.isEditable = true
        textView.autocorrectionType = .no
        textView.returnKeyType = .next
        textView.textContentType = .none
        textView.spellCheckingType = .no
        textView.smartInsertDeleteType = .no
        textView.textColor = inputProcessor.defaultTextColor
        textView.font = inputProcessor.defaultTextFont
        context.coordinator.setupTextView(textView)

        var toolbarItems = [UIBarButtonItem]()
        toolbarItems = [
            UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "keyboard.chevron.compact.down"),
                style: .plain,
                target: context.coordinator,
                action: #selector(context.coordinator.hideKeyboard)
            ),
        ]

        if !toolbarItems.isEmpty {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
            toolbar.items = toolbarItems
            toolbar.tintColor = Colors.Button.primary.uiColorFromRGB()
            textView.inputAccessoryView = toolbar
        }

        return textView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(inputProcessor: inputProcessor)
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<SeedPhraseTextView>) {}
}

extension SeedPhraseTextView {
    class Coordinator: NSObject, UITextViewDelegate {
        private weak var textView: UITextView?
        private unowned var inputProcessor: SeedPhraseInputProcessor

        private var textViewDidUpdateTextSubject = PassthroughSubject<Void, Never>()
        private var bag: Set<AnyCancellable> = []

        init(inputProcessor: SeedPhraseInputProcessor) {
            self.inputProcessor = inputProcessor
        }

        @objc
        func hideKeyboard() {
            UIApplication.shared.endEditing()
        }

        func setupTextView(_ textView: UITextView) {
            bag.removeAll()

            self.textView = textView

            // We can't use textView.publisher(\.text) because it was not implemented properly
            // so all changes are published only after editing ended.
            textViewDidUpdateTextSubject
                .debounce(for: 1, scheduler: DispatchQueue.main)
                .sink { [weak self] in
                    self?.validateInput()
                }
                .store(in: &bag)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            validateInput()
        }

        func textViewDidChange(_ textView: UITextView) {}

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            defer {
                textViewDidUpdateTextSubject.send(())
            }

            // If user typed or pasted something we can safely invalidate all previous results
            inputProcessor.resetValidation()

            if text.count > 1 {
                let oldText = textView.text ?? ""
                guard let oldTextRange = Range(range, in: oldText) else {
                    return true
                }

                // Prepare new copied text
                let preparedCopiedText = inputProcessor.prepare(copiedText: text)
                let newText = oldText.replacingCharacters(in: oldTextRange, with: " " + preparedCopiedText.string)
                let processedText = inputProcessor.validate(newInput: newText)

                // Calculating new caret position after pasting new text
                let newSelectedRange = NSRange(location: range.lowerBound + preparedCopiedText.string.count, length: 0)
                textView.attributedText = processedText

                textView.selectedRange = newSelectedRange
                // Because we updating text manually we need to update caret position and prevent inserting text by system
                return false
            }

            // We need to reset typing attributes after inserting space or erasing character, because all new input will
            // have same style as at the caret position.
            if text == " " || text.isEmpty {
                textView.typingAttributes = [
                    .foregroundColor: inputProcessor.defaultTextColor,
                    .font: inputProcessor.defaultTextFont,
                ]
            }

            return true
        }

        private func validateInput() {
            validateNewInput(textView?.text)
        }

        private func validateNewInput(_ newInput: String?) {
            guard let newInput, let textView = textView else {
                return
            }

            let validatedInput = inputProcessor.validate(newInput: newInput)
            let currentCaretPos = textView.selectedRange
            textView.attributedText = validatedInput
            textView.selectedRange = currentCaretPos
        }
    }
}
