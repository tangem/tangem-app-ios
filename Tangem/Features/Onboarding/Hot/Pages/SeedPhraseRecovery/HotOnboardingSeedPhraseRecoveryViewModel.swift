//
//  HotOnboardingSeedPhraseRecoveryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotOnboardingSeedPhraseRecoveryViewModel {
    let continueButtonTitle = Localization.commonContinue
    let responsibilityDescription = Localization.backupSeedResponsibility

    lazy var infoItem: InfoItem = makeInfoItem()
    lazy var phraseItem: PhraseItem = makePhraseItem()

    private let seedPhrase: SeedPhrase
    private weak var delegate: HotOnboardingSeedPhraseRecoveryDelegate?

    init(seedPhrase: SeedPhrase, delegate: HotOnboardingSeedPhraseRecoveryDelegate) {
        self.seedPhrase = seedPhrase
        self.delegate = delegate
    }
}

extension HotOnboardingSeedPhraseRecoveryViewModel {
    func onContinueTap() {
        delegate?.seedPhraseRecoveryContinue()
    }
}

// MARK: - Private methods

private extension HotOnboardingSeedPhraseRecoveryViewModel {
    func makeInfoItem() -> InfoItem {
        InfoItem(
            title: Localization.backupSeedTitle,
            description: Localization.backupSeedDescription("\(seedPhrase.words.count)")
        )
    }

    func makePhraseItem() -> PhraseItem {
        let wordsHalfCount = seedPhrase.words.count / 2
        return PhraseItem(
            words: seedPhrase.words,
            firstRange: 0 ..< wordsHalfCount,
            secondRange: wordsHalfCount ..< seedPhrase.words.count
        )
    }
}

// MARK: - Items

extension HotOnboardingSeedPhraseRecoveryViewModel {
    struct InfoItem {
        let title: String
        let description: String
    }

    struct PhraseItem {
        let words: [String]
        let firstRange: Range<Int>
        let secondRange: Range<Int>
    }
}

// MARK: - Input

extension HotOnboardingSeedPhraseRecoveryViewModel {
    struct SeedPhrase {
        let words: [String]
    }
}
