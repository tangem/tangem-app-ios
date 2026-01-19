//
//  AccountsAwareAddTokenNetworkDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization

/// Reusable data provider for AccountsAwareAddTokenViewModel network selector
struct AccountsAwareAddTokenNetworkDataProvider: AccountsAwareAddTokenNetworkSelectorDataProvider {
    let tokenItem: TokenItem
    let isSelectionAvailable: Bool
    let handleSelection: () -> Void

    var displayTitle: String { Localization.wcCommonNetwork }

    var trailingContent: (imageAsset: ImageType, name: String) {
        let iconProvider = NetworkImageProvider()

        return (
            imageAsset: iconProvider.provide(by: tokenItem.blockchain, filled: true),
            name: tokenItem.blockchain.displayName
        )
    }
}
