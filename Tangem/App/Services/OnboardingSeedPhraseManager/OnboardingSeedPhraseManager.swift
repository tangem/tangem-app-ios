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
    var mnemonic: Mnemonic? { get }

    @discardableResult
    func generateSeedPhrase() throws -> [String]
    func generateSeedMnemonic(using input: String) throws -> Mnemonic
}

class CommonOnboardingSeedPhraseManager: OnboardingSeedPhraseManager {
    private(set) var mnemonic: Mnemonic?

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
