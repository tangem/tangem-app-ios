//
//  HotOnboardingSeedPhraseCompletedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

final class HotOnboardingSeedPhraseCompletedViewModel {
    lazy var infoItem = makeInfoItem()
    lazy var continueItem = makeContinueItem()

    private weak var delegate: HotOnboardingSeedPhraseCompletedDelegate?

    init(delegate: HotOnboardingSeedPhraseCompletedDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Private methods

private extension HotOnboardingSeedPhraseCompletedViewModel {
    func makeInfoItem() -> InfoItem {
        InfoItem(
            icon: Assets.Onboarding.successCheckmark,
            title: "Backup Completed",
            description: "You successfully backed up your wallet."
        )
    }

    func makeContinueItem() -> ContinueItem {
        ContinueItem(
            title: "Continue",
            action: { [weak delegate] in
                delegate?.seedPhraseCompletedContinue()
            }
        )
    }
}

// MARK: - Types

extension HotOnboardingSeedPhraseCompletedViewModel {
    struct InfoItem {
        let icon: ImageType
        let title: String
        let description: String
    }

    struct ContinueItem {
        let title: String
        let action: () -> Void
    }
}
