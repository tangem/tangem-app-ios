//
//  SeedPhraseInputProcessor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

protocol SeedPhraseInputProcessor {
    var inputText: String { get }
    var inputTextPublisher: Published<NSAttributedString>.Publisher { get }
    var isSeedPhraseValidPublisher: Published<Bool>.Publisher { get }
    var inputErrorPublisher: Published<String?>.Publisher { get }
    var defaultTextColor: UIColor { get }
    var defaultTextFont: UIFont { get }

//    func prepare(_ input: String) -> NSAttributedString
//    func process(_ input: String, editingWord: String)
//    func validate(_ input: String)
    func validate(newInput: String) -> NSAttributedString
    func prepare(copiedText: String) -> NSAttributedString
    func userTypingText()
}

// extension SeedPhraseInputProcessor {
//    func process(_ input: String) {
//        process(input, editingWord: "")
//    }
// }

class DefaultSeedPhraseInputProcessor: SeedPhraseInputProcessor {
    let defaultTextColor: UIColor = Colors.Text.primary1.uiColorFromRGB()
    let invalidTextColor: UIColor = Colors.Text.warning.uiColorFromRGB()
    let defaultTextFont: UIFont = UIFonts.Regular.body

    @Published private var userInputSubject: NSAttributedString = .init(string: "")
    @Published private var isSeedPhraseValid: Bool = false
    @Published private var inputError: String? = nil

    private var dictionary: Set<String> = []

    var inputText: String { userInputSubject.string }

    var inputTextPublisher: Published<NSAttributedString>.Publisher { $userInputSubject }

    var isSeedPhraseValidPublisher: Published<Bool>.Publisher { $isSeedPhraseValid }

    var inputErrorPublisher: Published<String?>.Publisher { $inputError }

    init() {
        dictionary = Set(BIP39.Wordlist.en.words)
        userInputSubject = .init(string: "")
    }

//    func prepare(_ input: String) -> NSAttributedString {
//        prepare(input: input, editingWord: "").result
//    }
//
//    func process(_ input: String, editingWord: String) {
//        let preparationResult = prepare(input: input, editingWord: editingWord)
//        userInputSubject = preparationResult.result
//        validate(preparationResult: preparationResult)
//    }
//
//    func validate(_ input: String) {
//        let words = parse(userInput: input)
//        validate(words: words)
//    }

    func validate(newInput: String) -> NSAttributedString {
        if newInput.isEmpty {
            inputError = nil
            return NSAttributedString(string: "")
        }
        let words = newInput.split(separator: " ").map { String($0) }
        let preparationResult = prepare(words: words, editingWord: "")
        do {
            try BIP39().validate(mnemonicComponents: words)
            isSeedPhraseValid = true
        } catch {
            if preparationResult.containsInvalidWords {
                processValidationError(MnemonicError.invalidWords(words: []))
            } else {
                processValidationError(error)
            }
            isSeedPhraseValid = false
        }
        return preparationResult.result
    }

    func prepare(copiedText: String) -> NSAttributedString {
        do {
            let mnemonic = try Mnemonic(with: copiedText)
            return prepare(words: mnemonic.mnemonicComponents, editingWord: "").result
        } catch {
            processValidationError(error)
            let parsed = parse(input: copiedText)
            return prepare(words: parsed, editingWord: "").result
        }
    }

    func userTypingText() {
        isSeedPhraseValid = false
    }

    private func parse(input: String) -> [String] {
        input.split(separator: " ").map { String($0) }
    }

//    private func prepare(input: String, editingWord: String) -> PreparationResult {
//        let words = parse(userInput: input)
//        return prepare(words: words, editingWord: editingWord)
//    }

//    private func validate(preparationResult: PreparationResult) {
//        if preparationResult.containsInvalidWords {
//            processValidationError(MnemonicError.invalidWords(words: []))
//            isSeedPhraseValid = false
//            return
//        }
//        validate(words: preparationResult.parsedWords)
//    }

//    private func validate(words: [String]) {
//        do {
//            inputError = nil
//            try BIP39().validate(mnemonicComponents: words)
//            isSeedPhraseValid = true
//        } catch {
//            processValidationError(error)
//            AppLog.shared.error(error)
//            isSeedPhraseValid = false
//        }
//    }

    private func prepare(words: [String], editingWord: String) -> PreparationResult {
        let mutableStr = NSMutableAttributedString()
        let separator = " "
        var containsInvalidWords = false

        for i in 0 ..< words.count {
            let parsedWord = words[i]
            let isValidWord = dictionary.contains(parsedWord)
            if !isValidWord {
                containsInvalidWords = true
            }

            let wordColor = (isValidWord || editingWord == parsedWord) ? defaultTextColor : invalidTextColor
            let string = NSMutableAttributedString()
            string.append(NSAttributedString(string: parsedWord, attributes: [.foregroundColor: wordColor, .font: defaultTextFont]))
            string.append(NSAttributedString(string: separator, attributes: [.foregroundColor: defaultTextColor, .font: defaultTextFont]))
            mutableStr.append(string)
        }

        return PreparationResult(result: mutableStr, parsedWords: words, containsInvalidWords: containsInvalidWords)
    }

    private func parse(userInput: String) -> [String] {
        // Regular expression for parsing any letter in any language
        let regex = try! NSRegularExpression(pattern: "\\p{L}+")
        let range = NSRange(location: 0, length: userInput.count)
        let matches = regex.matches(in: userInput, range: range)
        let components = matches.compactMap { result -> String? in
            guard result.numberOfRanges > 0,
                  let stringRange = Range(result.range(at: 0), in: userInput) else {
                return nil
            }

            return String(userInput[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return components
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

extension DefaultSeedPhraseInputProcessor {
    private struct PreparationResult {
        let result: NSAttributedString
        let parsedWords: [String]
        let containsInvalidWords: Bool
    }
}
