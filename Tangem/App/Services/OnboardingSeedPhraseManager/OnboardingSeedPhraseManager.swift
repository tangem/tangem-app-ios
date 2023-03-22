//
//  OnboardingSeedPhraseManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk

protocol OnboardingSeedPhraseManager {
    var seedPhrase: [String] { get }

    @discardableResult
    func generateSeedPhrase() throws -> [String]
    func generateSeedMnemonic(using input: String) throws -> Mnemonic
}

class CommonOnboardingSeedPhraseManager {
    let defaultTextColor: UIColor = Colors.Text.primary1.uiColorFromRGB()
    let invalidTextColor: UIColor = Colors.Text.warning.uiColorFromRGB()
    let defaultTextFont: UIFont = UIFonts.Regular.body

    @Published private var userInputSubject: NSAttributedString = .init(string: "")
    @Published private var isSeedPhraseValid: Bool = false
    @Published private var inputError: String? = nil

    private var dictionary: Set<String> = []
    private var mnemonic: Mnemonic?
}

extension CommonOnboardingSeedPhraseManager: OnboardingSeedPhraseManager {
    var seedPhrase: [String] { mnemonic?.mnemonicComponents ?? [] }

    @discardableResult
    func generateSeedPhrase() throws -> [String] {
        let mnemonic = try Mnemonic(with: .bits128, wordList: .en)
        self.mnemonic = mnemonic
        return mnemonic.mnemonicComponents
    }

    func generateSeedMnemonic(using input: String) throws -> Mnemonic {
        return try Mnemonic(with: input)
    }
}
