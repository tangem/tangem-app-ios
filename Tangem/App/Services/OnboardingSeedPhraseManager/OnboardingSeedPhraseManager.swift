//
//  OnboardingSeedPhraseManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSdk

typealias OnboardingSeedPhraseManager = OnboardingSeedPhraseGenerator

protocol OnboardingSeedPhraseGenerator {
    var seedPhrase: [String] { get }
    @discardableResult
    func generateSeedPhrase() throws -> [String]
}

private struct OnboardingSeedPhraseManagerKey: InjectionKey {
    static var currentValue: OnboardingSeedPhraseManager = CommonOnboardingSeedPhraseManager()
}

extension InjectedValues {
    var onboardingSeedPhraseManager: OnboardingSeedPhraseManager {
        get { Self[OnboardingSeedPhraseManagerKey.self] }
        set { Self[OnboardingSeedPhraseManagerKey.self] = newValue }
    }
}

class CommonOnboardingSeedPhraseManager {
    private var mnemonic: Mnemonic?
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
}
