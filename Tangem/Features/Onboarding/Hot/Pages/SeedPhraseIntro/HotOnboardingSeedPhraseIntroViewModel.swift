//
//  HotOnboardingSeedPhraseIntroViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class HotOnboardingSeedPhraseIntroViewModel {
    let continueButtonTitle = Localization.commonContinue

    lazy var commonItem: CommonItem = makeCommonItem()
    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: HotOnboardingSeedPhraseIntroDelegate?

    private let wordsCount: Int = 12

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
            title: Localization.backupInfoTitle,
            subtitle: Localization.backupInfoDescription("\(wordsCount)")
        )
    }

    func makeInfoItems() -> [InfoItem] {
        [
            InfoItem(
                title: Localization.backupInfoSaveTitle,
                description: Localization.backupInfoSaveDescription("\(wordsCount)"),
                icon: Assets.lock24
            ),
            InfoItem(
                title: Localization.backupInfoKeepTitle,
                description: Localization.backupInfoKeepDescription,
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
