//
//  OnboardingSeedPhraseManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk
import SwiftUI
import Combine

typealias OnboardingSeedPhraseManager = OnboardingSeedPhraseGenerator & SeedPhraseInputProcessor

protocol OnboardingSeedPhraseGenerator {
    var seedPhrase: [String] { get }
    @discardableResult
    func generateSeedPhrase() throws -> [String]
    func generateSeedUsingInput() throws -> Mnemonic
}

private struct OnboardingSeedPhraseManagerKey: InjectionKey {
    static var currentValue: OnboardingSeedPhraseManager = CommonOnboardingSeedPhraseManager()
}

extension InjectedValues {
    var onboardingSeedPhraseManager: OnboardingSeedPhraseManager {
        get { Self[OnboardingSeedPhraseManagerKey.self] }
        set { Self[OnboardingSeedPhraseManagerKey.self] = newValue }
    }

    var seedPhraseInputProcessor: SeedPhraseInputProcessor { Self[OnboardingSeedPhraseManagerKey.self] }

    var seedPhraseGenerator: OnboardingSeedPhraseGenerator { Self[OnboardingSeedPhraseManagerKey.self] }
}

protocol SeedPhraseInputProcessor {
    var inputTextPublisher: Published<NSAttributedString>.Publisher { get }
    var isValidSeedPhrasePublisher: Published<Bool>.Publisher { get }
    var inputErrorPublisher: Published<String?>.Publisher { get }
    var defaultTextColor: UIColor { get }
    var defaultTextFont: UIFont { get }
    func setupProcessor()
    func prepare(input: String) -> NSAttributedString
    func prepare(input: String, editingWord: String) -> NSAttributedString
    func process(_ input: String)
    func process(_ input: String, editingWord: String)
    func validate(input: String)
}

class CommonOnboardingSeedPhraseManager {
    private var mnemonic: Mnemonic?

    @Published private var userInputSubject: NSAttributedString = .init(string: "")
    @Published private var isSeedPhraseValid: Bool = false
    @Published private var inputError: String? = nil

    var dict: [String] = []
    var keyedDict: [Character: [String]] = [:]
}

extension CommonOnboardingSeedPhraseManager: OnboardingSeedPhraseGenerator {
    var seedPhrase: [String] {
        guard let mnemonic = mnemonic else {
            return []
        }

        return mnemonic.mnemonicComponents
    }

    @discardableResult
    func generateSeedPhrase() throws -> [String] {
        let mnemonic = try Mnemonic(with: .bits128, wordList: .en)
        self.mnemonic = mnemonic
        return mnemonic.mnemonicComponents
    }

    func generateSeedUsingInput() throws -> Mnemonic {
        let mnemonic = try Mnemonic(with: userInputSubject.string)
        self.mnemonic = mnemonic
        return mnemonic
    }
}

extension CommonOnboardingSeedPhraseManager: SeedPhraseInputProcessor {
    var inputTextPublisher: Published<NSAttributedString>.Publisher { $userInputSubject }

    var isValidSeedPhrasePublisher: Published<Bool>.Publisher { $isSeedPhraseValid }

    var inputErrorPublisher: Published<String?>.Publisher { $inputError }

    var defaultTextColor: UIColor {
        Colors.Text.primary1.uiColorFromRGB()
    }

    var defaultTextFont: UIFont {
        UIFonts.Regular.body
    }

    func setupProcessor() {
        // Add setup of dict language when other languages will be added to SDK
        dict = BIP39.Wordlist.en.words
        keyedDict = .init(grouping: dict, by: { $0.first ?? " " })
        userInputSubject = .init(string: "")
        AppLog.shared.debug(dict)
    }

    func prepare(input: String) -> NSAttributedString {
        prepare(input: input, editingWord: "")
    }

    func process(_ input: String) {
        process(input, editingWord: "")
    }

    func process(_ input: String, editingWord: String) {
        userInputSubject = prepare(input: input, editingWord: editingWord)
        validate(input: input)
    }

    func prepare(input: String, editingWord: String) -> NSAttributedString {
        let parsed = parse(mnemonicString: input)
        return prepare(words: parsed, editingWord: editingWord)
    }

    func validate(input: String) {
        do {
            inputError = nil
            let parsedWords = parse(mnemonicString: input)
            try BIP39().validate(mnemonicComponents: parsedWords)
            isSeedPhraseValid = true
        } catch {
            processValidationError(error)
            AppLog.shared.error(error)
            isSeedPhraseValid = false
        }
    }

    private func prepare(words: [String], editingWord: String) -> NSAttributedString {
        let mutableStr = NSMutableAttributedString()
        let invalidWordColor = Colors.Text.warning.uiColorFromRGB()
        let separator = " "

        for i in 0 ..< words.count {
            let parsedWord = words[i]
            let isValidWord = dict.contains(parsedWord)
            var color = isValidWord ? defaultTextColor : invalidWordColor
            if editingWord == parsedWord {
                color = defaultTextColor
            }
            let string = NSMutableAttributedString()
            string.append(NSAttributedString(string: parsedWord, attributes: [.foregroundColor: color, .font: defaultTextFont]))
            string.append(NSAttributedString(string: separator, attributes: [.foregroundColor: defaultTextColor, .font: defaultTextFont]))
            mutableStr.append(string)
        }

        return mutableStr
    }

    private func parse(mnemonicString: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: "\\p{L}+")
            let range = NSRange(location: 0, length: mnemonicString.count)
            let matches = regex.matches(in: mnemonicString, range: range)
            let components = matches.compactMap { result -> String? in
                guard result.numberOfRanges > 0,
                      let stringRange = Range(result.range(at: 0), in: mnemonicString) else {
                    return nil
                }

                return String(mnemonicString[stringRange]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }

            return components
        } catch {
            // Unrealistic case, because this regular expression is tested, it is not dynamic and shouldn't throw an error
            // But to make it easier to call from outside add this do-catch block
            AppLog.shared.debug("[Seed phrase] Failed to create regular expression. Error: \(error)")
            return []
        }
    }

    private func processValidationError(_ error: Error) {
        guard let mnemonicError = error as? MnemonicError else {
            inputError = error.localizedDescription
            return
        }

        switch mnemonicError {
        case .invalidEntropyLength, .invalidWordCount, .invalidWordsFile, .mnenmonicCreationFailed, .normalizationFailed:
            break
        case .invalidCheksum:
            inputError = "Invalid checksum. Please check words order"
        case .wrongWordCount:
            return
        case .unsupportedLanguage:
            inputError = "Currently input language is not supported"
        case .invalidWords:
            inputError = "Invalid seed phrase, please check your spelling"
        @unknown default:
            break
        }
    }
}
