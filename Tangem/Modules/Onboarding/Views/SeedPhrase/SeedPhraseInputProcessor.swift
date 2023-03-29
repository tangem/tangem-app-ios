//
//  SeedPhraseInputProcessor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

//<<<<<<< HEAD
//protocol SeedPhraseInputProcessor {
//    var inputText: String { get }
//    var inputTextPublisher: Published<NSAttributedString>.Publisher { get }
//    var isSeedPhraseValidPublisher: Published<Bool>.Publisher { get }
//    var inputErrorPublisher: Published<String?>.Publisher { get }
//    var defaultTextColor: UIColor { get }
//    var defaultTextFont: UIFont { get }
//    var suggestionsPublisher: Published<[String]>.Publisher { get }
//    var suggestionCaretPositionPublisher: Published<NSRange?>.Publisher { get }
//
//    func setupProcessor()
//    func prepare(_ input: String) -> NSAttributedString
//    func process(_ input: String, editingWord: String, isEndTypingWord: Bool)
//    func insertSuggestion(_ word: String)
//    func validate(_ input: String)
//    func updateSuggestions(for inputWord: String, in range: NSRange?)
//    func clearSuggestions()
//}
//
//extension SeedPhraseInputProcessor {
//    func process(_ input: String) {
//        process(input, editingWord: "")
//    }
//
//    func process(_ input: String, editingWord: String) {
//        process(input, editingWord: editingWord, isEndTypingWord: false)
//    }
//
//    func process(_ input: String, isEndTypingWord: Bool) {
//        process(input, editingWord: "", isEndTypingWord: isEndTypingWord)
//    }
//}

class SeedPhraseInputProcessor {
    let defaultTextColor: UIColor = Colors.Text.primary1.uiColorFromRGB()
    let invalidTextColor: UIColor = Colors.Text.warning.uiColorFromRGB()
    let defaultTextFont: UIFont = UIFonts.Regular.body

    @Published private(set) var validatedSeedPhrase: String?
    @Published private(set) var inputError: String? = nil
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var suggestionCaretPosition: NSRange? = nil

    var isSeedPhraseValidPublisher: AnyPublisher<Bool, Never> {
        $validatedSeedPhrase
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    private var dictionary: Set<String> = []
    private var rangeForSuggestingWord: NSRange?

    
//    var isSeedPhraseValidPublisher: Published<Bool>.Publisher { $isSeedPhraseValid }

//    var suggestionsPublisher: Published<[String]>.Publisher { $suggestions }
//    var suggestionCaretPositionPublisher: Published<NSRange?>.Publisher { $suggestionCaretPosition }

    init() {
        dictionary = Set(BIP39.Wordlist.en.words)
    }

//    func prepare(_ input: String) -> NSAttributedString {
//        prepare(input: input, editingWord: "", isEndTypingWord: true).result
//    }
//
//    func process(_ input: String, editingWord: String, isEndTypingWord: Bool) {
//        let preparationResult = prepare(input: input, editingWord: editingWord, isEndTypingWord: isEndTypingWord)
//        userInputSubject = preparationResult.result
//        validate(preparationResult: preparationResult)
//    }
//
//    func validate(_ input: String) {
//        let words = parse(userInput: input)
//        validate(words: words)
//    }
//
  
//
//    func updateSuggestions(for inputWord: String, in range: NSRange?) {
//        if inputWord.isEmpty {
//            clearSuggestions()
//            return
//        }
//
//        rangeForSuggestingWord = range
//        suggestions = dictionary.filter { $0.starts(with: inputWord) }
//    }
//
//    func clearSuggestions() {
//        suggestions = []
//        rangeForSuggestingWord = nil
//    }
//
//    private func prepare(input: String, editingWord: String, isEndTypingWord: Bool) -> PreparationResult {
//        let words = parse(userInput: input)
//        return prepare(words: words, editingWord: editingWord, isEndTypingWord: isEndTypingWord)
//    }
//
//    private func validate(preparationResult: PreparationResult) {
//        if preparationResult.containsInvalidWords {
//            processValidationError(MnemonicError.invalidWords(words: []))
//            isSeedPhraseValid = false
//            return
//        }
//        validate(words: preparationResult.parsedWords)
//    }
//
//    private func validate(words: [String]) {
//        do {
//=======
    func validate(newInput: String) -> NSAttributedString {
        if newInput.isEmpty {
            inputError = nil
            validatedSeedPhrase = nil
            return NSAttributedString(string: "")
        }
        let words = parse(input: newInput)
        let preparationResult = processInput(words: words)
        do {
            try BIP39().validate(mnemonicComponents: words)
            inputError = nil
            validatedSeedPhrase = newInput
        } catch {
            if preparationResult.invalidWords.isEmpty {
                processValidationError(error)
            } else {
                processValidationError(MnemonicError.invalidWords(words: preparationResult.invalidWords))
            }
            validatedSeedPhrase = nil
        }
        return preparationResult.attributedText
    }

    func prepare(copiedText: String) -> NSAttributedString {
        do {
            let mnemonic = try Mnemonic(with: copiedText)
            return processInput(words: mnemonic.mnemonicComponents).attributedText
        } catch {
            let parsed = parse(input: copiedText)
            return processInput(words: parsed).attributedText
        }
    }

   func resetValidation() {
        validatedSeedPhrase = nil
    }
    
    func insertSuggestion(_ word: String) {
//        let currentInput = userInputSubject.string
//        
//        guard let range = rangeForSuggestingWord else {
//            return
//        }
//        
//        let newInput: String
//        if let replacementRange = Range(range, in: currentInput) {
//            newInput = currentInput.replacingCharacters(in: replacementRange, with: word)
//        } else {
//            newInput = currentInput + word
//        }
//        
//        process(newInput, isEndTypingWord: true)
//        suggestionCaretPosition = NSRange(location: range.lowerBound + word.count + 1, length: 0)
//        clearSuggestions()
    }

    private func parse(input: String) -> [String] {
        input.split(separator: " ").map { String($0) }
    }

    private func processInput(words: [String]) -> ProcessedInput {
        let mutableStr = NSMutableAttributedString()
        let separator = " "
        var invalidWords = [String]()

        for i in 0 ..< words.count {
            let parsedWord = words[i]
            let isValidWord = dictionary.contains(parsedWord)
            if !isValidWord {
                invalidWords.append(parsedWord)
            }

            let wordColor = isValidWord ? defaultTextColor : invalidTextColor
            let string = NSMutableAttributedString()
            string.append(NSAttributedString(string: parsedWord, attributes: [.foregroundColor: wordColor, .font: defaultTextFont]))
//            if (i == words.count - 1 && isEndTypingWord) || i < words.count - 1 {
                string.append(NSAttributedString(string: separator, attributes: [.foregroundColor: defaultTextColor, .font: defaultTextFont]))
//            }
            mutableStr.append(string)
        }

        return ProcessedInput(attributedText: mutableStr, invalidWords: invalidWords)
    }

    private func processValidationError(_ error: Error) {
        guard let mnemonicError = error as? MnemonicError else {
            inputError = error.localizedDescription
            return
        }

        switch mnemonicError {
        case .invalidEntropyLength, .invalidWordCount, .invalidWordsFile, .mnenmonicCreationFailed, .normalizationFailed, .wrongWordCount:
            inputError = nil
        case .invalidCheksum:
            inputError = "Invalid checksum. Please check words order"
        case .unsupportedLanguage, .invalidWords:
            inputError = "Invalid seed phrase, please check your spelling"
        @unknown default:
            break
        }
    }
}

extension SeedPhraseInputProcessor {
    private struct ProcessedInput {
        let attributedText: NSAttributedString
        let invalidWords: [String]
    }
}
