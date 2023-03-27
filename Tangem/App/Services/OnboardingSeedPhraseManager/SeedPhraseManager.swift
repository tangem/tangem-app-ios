//
//  SeedPhraseManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk

protocol SeedPhraseManager {
    var seedPhrase: [String] { get }

    @discardableResult
    func generateSeedPhrase() throws -> [String]
}

class CommonSeedPhraseManager: SeedPhraseManager {
    private var mnemonic: Mnemonic?

    var seedPhrase: [String] { mnemonic?.mnemonicComponents ?? [] }

    @discardableResult
    func generateSeedPhrase() throws -> [String] {
        let mnemonic = try Mnemonic(with: .bits128, wordList: .en)
        self.mnemonic = mnemonic
        return mnemonic.mnemonicComponents
    }
}
