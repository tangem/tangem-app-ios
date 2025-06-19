//
//  HotOnboardingCreateWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets

final class HotOnboardingCreateWalletViewModel {
    let title = "Create Mobile Wallet"
    let createButtonTitle = "Create"

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
                title: "Keys are stored in the app",
                subtitle: "Get notified of incoming transactions"
            ),
            InfoItem(
                icon: Assets.lock24,
                title: "Seed phrase backup",
                subtitle: "Stay up to date with the latest features and news"
            ),
        ]
    }
}

// MARK: - Types

extension HotOnboardingCreateWalletViewModel {
    struct InfoItem {
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}
