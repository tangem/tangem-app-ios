//
//  HotOnboardingCreateWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

final class HotOnboardingCreateWalletViewModel {
    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: HotOnboardingCreateWalletDelegate?

    init(delegate: HotOnboardingCreateWalletDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension HotOnboardingCreateWalletViewModel {
    func onCreateTap() {
        delegate?.onCreateWallet()
    }
}

// MARK: - Private methods

private extension HotOnboardingCreateWalletViewModel {
    func makeInfoItems() -> [InfoItem] {
        [
            InfoItem(
                icon: Assets.cog24,
                title: Localization.hwCreateKeysTitle,
                subtitle: Localization.hwCreateKeysDescription
            ),
            InfoItem(
                icon: Assets.lock24,
                title: Localization.hwCreateSeedTitle,
                subtitle: Localization.hwCreateSeedDescription
            ),
        ]
    }
}

// MARK: - Types

extension HotOnboardingCreateWalletViewModel {
    struct InfoItem: Identifiable {
        let id: UUID = .init()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}
