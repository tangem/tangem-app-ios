//
//  CommonHotOnboardingSeedPhraseResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonHotOnboardingSeedPhraseResolver {
    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}

// MARK: - HotOnboardingSeedPhraseResolver

extension CommonHotOnboardingSeedPhraseResolver: HotOnboardingSeedPhraseResolver {
    var words: [String] {
        // [REDACTED_TODO_COMMENT]
        [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
    }

    var validationWords: HotOnboardingSeedPhraseValidationWords {
        let words = words
        return HotOnboardingSeedPhraseValidationWords(
            second: words[1],
            seventh: words[6],
            eleventh: words[10]
        )
    }
}
