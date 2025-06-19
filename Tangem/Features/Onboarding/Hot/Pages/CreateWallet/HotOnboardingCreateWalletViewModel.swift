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
    let infoItems: [InfoItem]
    let createItem: CreateItem

    private let onCreate: () -> Void

    init(onCreate: @escaping () -> Void) {
        self.onCreate = onCreate
        infoItems = [
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
        createItem = CreateItem(
            title: "Create",
            action: onCreate
        )
    }

    struct InfoItem {
        let icon: ImageType
        let title: String
        let subtitle: String
    }

    struct CreateItem {
        let title: String
        let action: () -> Void
    }
}
