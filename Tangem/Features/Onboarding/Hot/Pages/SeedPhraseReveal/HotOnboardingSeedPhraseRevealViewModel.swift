//
//  HotOnboardingSeedPhraseRevealViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotOnboardingSeedPhraseRevealViewModel {
    lazy var infoItem: InfoItem = makeInfoItem()
    lazy var phraseItem: PhraseItem = makePhraseItem()

    private let seedPhrase: SeedPhrase

    init(seedPhraseResolver: HotOnboardingSeedPhraseResolver) {
        seedPhrase = SeedPhrase(words: seedPhraseResolver.words)
    }
}

// MARK: - Private methods

private extension HotOnboardingSeedPhraseRevealViewModel {
    func makeInfoItem() -> InfoItem {
        InfoItem(
            title: Localization.backupSeedTitle,
            description: Localization.backupSeedCaution(seedPhrase.words.count)
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

extension HotOnboardingSeedPhraseRevealViewModel {
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

// MARK: - Types

private extension HotOnboardingSeedPhraseRevealViewModel {
    struct SeedPhrase {
        let words: [String]
    }
}
