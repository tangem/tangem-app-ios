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
    class Coordinator: NSObject, UITextViewDelegate {
        var textUpdateSubscription: AnyCancellable?
        let inputProcessor: SeedPhraseInputProcessor
        var isUserTypingText = false
        var isInputValidated = false

        init(inputProcessor: SeedPhraseInputProcessor) {
            self.inputProcessor = inputProcessor
        }

        @objc
        func hideKeyboard() {
            UIApplication.shared.endEditing()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            _ = inputProcessor.process(textView.attributedText.string)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if !isInputValidated, !isUserTypingText {
                inputProcessor.process(textView.text)
                isInputValidated = true
            } else {
                isUserTypingText = false
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            print("TextView should change text in range")

            func setupText(_ input: String, editingWord: String = "") {
                print("Going to process text")
//                textView.attributedText = inputProcessor.prepare(input: input, editingWord: editingWord)
                inputProcessor.process(input, editingWord: editingWord)
                print("Text processed")
            }

            isUserTypingText = true
            isInputValidated = false
            let currentSelectedRange = textView.selectedRange
            let oldText = textView.text!
            let oldTextRange = Range(range, in: oldText)!

            if text.count > 1 {
                let preparedString = inputProcessor.prepare(input: text)

                let newText = oldText.replacingCharacters(in: oldTextRange, with: preparedString.string)
                setupText(newText)
//                inputProcessor.process(newText)
//                textView.attributedText = inputProcessor.prepare(input: newText)
                isInputValidated = true
                let newSelectedRange = NSRange(location: range.lowerBound + preparedString.string.count, length: 0)
                DispatchQueue.main.async {
                    textView.selectedRange = newSelectedRange
                }

                print("Returning after text processing")
                return false
            }

            let lastChar: Character = text.last ?? ","
            let isNewCharSingleSpace = lastChar == " "
            guard lastChar.isLetter || lastChar == "," || lastChar == "." || lastChar.isWhitespace else {
                print("Returning after text processing")
                return false
            }

            guard range.lowerBound == textView.text.count || textView.text.isEmpty else {
                let replacedText = textView.text.replacingCharacters(in: oldTextRange, with: text)
                textView.text = replacedText

                let firstPos = textView.closestPosition(to: .zero)

                var word = ""
                var nextWord = ""
                let textPosition = textView.position(from: firstPos!, offset: range.lowerBound)!
                let newCaretPosition = textView.position(from: firstPos!, offset: range.lowerBound + text.count)
                if let wordRange = textView.tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: UITextDirection(rawValue: 1)),
                   let foundWord = textView.text(in: wordRange) {
                    word = foundWord
                }

                if let newCaretPosition,
                   let nextWordRange = textView.tokenizer.rangeEnclosingPosition(newCaretPosition, with: .word, inDirection: .storage(.forward)),
                   let foundWord = textView.text(in: nextWordRange) {
                    nextWord = foundWord
                }

                setupText(textView.text, editingWord: nextWord.isEmpty && !word.isEmpty ? word : nextWord)
//                textView.attributedText = inputProcessor.prepare(input: textView.text, editingWord: nextWord.isEmpty && !word.isEmpty ? word : nextWord)
//                inputProcessor.process(textView.text, editingWord: nextWord.isEmpty && !word.isEmpty ? word : nextWord)

                isInputValidated = true
                let newCaretLocation: Int
                if text.isEmpty {
                    newCaretLocation = currentSelectedRange.lowerBound == 0 ? 0 : currentSelectedRange.lowerBound - 1
                } else if word.isEmpty, isNewCharSingleSpace {
                    newCaretLocation = currentSelectedRange.lowerBound
                } else {
                    newCaretLocation = currentSelectedRange.lowerBound + text.count
                }

                textView.selectedRange = NSRange(location: newCaretLocation, length: 0)
                isInputValidated = false
                print("Returning after text processing")
                return false
            }

            let currentText = textView.text ?? ""
            if lastChar.isNewline {
                if currentText.isEmpty || currentText.last?.isPunctuation ?? false {
                    print("Returning after text processing")
                    return false
                }
                setupText(textView.text + " ")
//                textView.attributedText = inputProcessor.prepare(input: textView.attributedText.string + " ")
//                inputProcessor.process(textView.attributedText.string + " ")
                isInputValidated = true

                print("Returning after text processing")
                return false
            }
            if lastChar.isPunctuation || lastChar.isWhitespace {
                setupText(textView.text + text)
                //                textView.attributedText = inputProcessor.prepare(input: textView.attributedText.string + text)
                //                inputProcessor.process(textView.attributedText.string + text)
                isInputValidated = true

                print("Returning after text processing")
                return false
            }

            inputProcessor.validate(input: textView.text + text)
            print("Returning after text processing")
            return true
        }
    }

    private let inputProcessor: SeedPhraseInputProcessor

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
        context.coordinator.textUpdateSubscription = inputProcessor.inputTextPublisher
            .print("Receive new text. Assigning to textView")
            .sink(receiveValue: {
                textView.attributedText = $0
            })
//            .assign(to: \.attributedText, on: textView)

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
            toolbar.tintColor = UIColor.black
            textView.inputAccessoryView = toolbar
        }

        return textView
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(inputProcessor: inputProcessor)
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<SeedPhraseTextView>) {}
}
