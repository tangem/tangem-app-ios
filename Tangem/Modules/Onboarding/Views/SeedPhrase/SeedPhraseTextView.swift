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
        let coordinator = context.coordinator
        coordinator.textUpdateSubscription = inputProcessor.inputTextPublisher
            .dropFirst()
            .sink(receiveValue: { [weak coordinator] newText in
                coordinator?.isInputValidated = true
                textView.attributedText = newText
            })
        context.coordinator.caretPosUpdateSubscription = inputProcessor.suggestionCaretPositionPublisher
            .compactMap { $0 }
            .sink(receiveValue: { newPos in
                textView.selectedRange = newPos
            })
//            .weakAssign(to: \.attributedText, on: textView)

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

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<SeedPhraseTextView>) {
        DispatchQueue.main.async {
            uiView.becomeFirstResponder()
        }
    }
}

extension SeedPhraseTextView {
    class Coordinator: NSObject, UITextViewDelegate {
        var textUpdateSubscription: AnyCancellable?
        var caretPosUpdateSubscription: AnyCancellable?
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
            _ = inputProcessor.process(textView.attributedText.string, isEndTypingWord: true)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            if !isInputValidated, !isUserTypingText {
                inputProcessor.process(textView.text)
                isInputValidated = true
                inputProcessor.clearSuggestions()
            } else {
                isUserTypingText = false
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            isUserTypingText = true
            isInputValidated = false
            let currentSelectedRange = textView.selectedRange
            let oldText = textView.text ?? ""

            func clearSuggestions() {
                inputProcessor.clearSuggestions()
            }

            func getWordRange(at position: UITextPosition, within textRange: UITextRange) -> NSRange {
                let location = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
                let length = textView.offset(from: textRange.start, to: textRange.end)
                return NSRange(location: location, length: length)
            }

            func findWordToTheLeft(from position: UITextPosition) -> (word: String, range: NSRange?) {
                if let wordRange = textView.tokenizer.rangeEnclosingPosition(position, with: .word, inDirection: .storage(.backward)),
                   let foundWord = textView.text(in: wordRange) {
                    return (foundWord, getWordRange(at: position, within: wordRange))
                }

                return ("", nil)
            }

            guard let oldTextRange = Range(range, in: oldText) else {
                clearSuggestions()
                return true
            }

            // If user inserting text from clipboard
            if text.count > 1 {
                clearSuggestions()
                // Prepare new text, replace invalid symbols with spaces
                let preparedString = inputProcessor.prepare(text)

                // Create final text with prepared copied text. Adding space to prevent joining previous word and first word
                // in prepared text if carret is placed at the end of the word before pasting
                let newText = oldText.replacingCharacters(in: oldTextRange, with: " " + preparedString.string)
                inputProcessor.process(newText, isEndTypingWord: true)

                // Before changing caret position we need to indicate that this text was already processed
                isInputValidated = true
                let newSelectedRange = NSRange(location: range.lowerBound + preparedString.string.count, length: 0)

                textView.selectedRange = newSelectedRange
                return false
            }

            let lastChar: Character = text.last ?? ","
            guard isValidReplacement(text.last) else {
                clearSuggestions()
                return false
            }

            let isEndTypingWord = isValidPunctuationChar(text.last)
            let firstPos = textView.beginningOfDocument
            if range.lowerBound == textView.text.count || textView.text.isEmpty {
                // Adding new character to the end of the line or this is first charater.

                let currentText = textView.text ?? ""
                // If new character is letter we can add it to the end of line and validate input.
                if lastChar.isLetter {
//                    var replacedText = textView.text.replacingCharacters(in: oldTextRange, with: text)
//                    if replacedText.last?.isWhitespace ?? false {
//                        replacedText.removeLast()
//                    }
//
//                    textView.text = replacedText

                    if let stringEndPos = textView.position(from: firstPos, offset: range.lowerBound) {
                        let searchResult = findWordToTheLeft(from: stringEndPos)
                        if let range = searchResult.range, !searchResult.word.isEmpty {
                            inputProcessor.updateSuggestions(for: searchResult.word + text, in: NSRange(location: range.location, length: range.length + 1))
                        } else {
                            inputProcessor.updateSuggestions(for: text, in: NSRange(location: textView.selectedRange.location, length: 1))
                        }
//                        inputProcessor.process(replacedText, editingWord: searchResult.word)
                    }

                    inputProcessor.validate(currentText + text)
                    return true
                } else if !currentText.isEmpty {
                    inputProcessor.process(currentText + " ", isEndTypingWord: true)
                    clearSuggestions()
                }

                // No need to add a punctuation or a whitespace when text view is empty.
//                if currentText.isEmpty {
//                    return false
//                }
                isInputValidated = true
                return false
            }

            // When user trying to edit text not at the end of line.
            // This includes character removal from the end of line
            // because textView replacing last character with void.
            let replacedText = textView.text.replacingCharacters(in: oldTextRange, with: text)
            textView.text = replacedText

            var word = ""
            var leftSideWordRange: NSRange?
            var nextWord = ""

            ////             Start position of text to be replaced. We need this position to find word which is editing
//            if let firstPos = textView.closestPosition(to: .zero) {
            // Next, we need to find words that should change their colour to the default colour when editing,
            // if they have been marked as misspelled words
            // Try to find the word in the left direction. If caret is placed at the end of the word
            // we need to search to the left side of the caret
            if let textPosition = textView.position(from: firstPos, offset: range.lowerBound),
               let wordRange = textView.tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: .storage(.backward)),
               let foundWord = textView.text(in: wordRange) {
                word = foundWord
                let location = textView.offset(from: firstPos, to: wordRange.start)
                let length = textView.offset(from: wordRange.start, to: wordRange.end)
                leftSideWordRange = NSRange(location: location, length: length)
            }

            // Try to find the word in the right direction. If caret is placed at the begining of the word
            // we need to search to the right side of the caret
            if let newCaretPosition = textView.position(from: firstPos, offset: range.lowerBound + text.count), // Caret position after replacing text
               let nextWordRange = textView.tokenizer.rangeEnclosingPosition(newCaretPosition, with: .word, inDirection: .storage(.forward)),
               let foundWord = textView.text(in: nextWordRange) {
                nextWord = foundWord
            }
//            }

            // If we didn't found the word to the right of the caret but did found word to the left of the caret
            // we can use left side word, otherwise use the right side word. If the right side word is empty
            // then processor will ignore empty string
            inputProcessor.process(textView.text, editingWord: nextWord.isEmpty && !word.isEmpty ? word : nextWord, isEndTypingWord: isEndTypingWord)

            if leftSideWordRange != nil, !isEndTypingWord {
                inputProcessor.updateSuggestions(for: word, in: leftSideWordRange)
            }

            // Input was already validated so no need to validate it again after moving caret to a new position
            isInputValidated = true

            // We need to select new position for carret, because textView moving caret to an end of a line
            // when setup new attributed string/
            let newCaretLocation: Int
            if text.isEmpty {
                newCaretLocation = currentSelectedRange.lowerBound == 0 ? 0 : currentSelectedRange.lowerBound - 1
            } else if word.isEmpty, lastChar.isWhitespace {
                newCaretLocation = currentSelectedRange.lowerBound
            } else {
                newCaretLocation = currentSelectedRange.lowerBound + text.count
            }

            textView.selectedRange = NSRange(location: newCaretLocation, length: 0)

            // Reset input validation flag so when user trying to move caret updated input will be validated
            // E.g. when user typed two words, make a mistate at the begining of the second word
            // remove wrong character and occasionaly removed space, if after that user move caret text won't be validated
            isInputValidated = false
            return false
        }

        private func isValidReplacement(_ char: Character?) -> Bool {
            guard let char else {
                // Nil value indicates that user is trying to erase symbol which is valid replacement
                return true
            }

            // , and . is usefull for custom keyboards that adds this punctuation symbols on sides of spacebar
            // All other symbols are invalid for seed phrase, so we can skip them
            return char.isLetter || isValidPunctuationChar(char)
        }

        private func isValidPunctuationChar(_ char: Character?) -> Bool {
            guard let char else {
                return false
            }

            return char == "," || char == "." || char.isWhitespace
        }
    }
}
