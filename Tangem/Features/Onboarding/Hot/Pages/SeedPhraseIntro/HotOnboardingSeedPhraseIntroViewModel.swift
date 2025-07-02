//
//  HotOnboardingSeedPhraseIntroViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

final class HotOnboardingSeedPhraseIntroViewModel {
    let continueButtonTitle = "Continue"

    lazy var commonItem: CommonItem = makeCommonItem()
    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: HotOnboardingSeedPhraseIntroDelegate?

    init(delegate: HotOnboardingSeedPhraseIntroDelegate) {
        self.delegate = delegate
    }
}

extension HotOnboardingSeedPhraseIntroViewModel {
    func onContinueTap() {
        delegate?.seedPhraseIntroContinue()
    }
}

// MARK: - Private methods

private extension HotOnboardingSeedPhraseIntroViewModel {
    func makeCommonItem() -> CommonItem {
        CommonItem(
            title: "Recovery phrase",
            subtitle: "Your Secret Recovery Phrase is a fixed set of 12 random words used to access and recover your wallet."
        )
    }

    func makeInfoItems() -> [InfoItem] {
        [
            InfoItem(
                title: "No Recovery Possible",
                description: "Save these 12 words in a secure location, such as a password manager, and never share them with anyone.",
                icon: Assets.lock24
            ),
            InfoItem(
                title: "Keep It Safe",
                description: "These words can’t be recovered if lost. Make sure to keep it somewhere secure.",
                icon: Assets.cog24
            ),
        ]
    }
}

// MARK: - Items

extension HotOnboardingSeedPhraseIntroViewModel {
    struct CommonItem {
        let title: String
        let subtitle: String
    }

    struct InfoItem: Identifiable {
        let id: UUID = .init()
        let title: String
        let description: String
        let icon: ImageType
    }
}
