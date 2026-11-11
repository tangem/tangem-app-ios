//
//  AllServicesItemsProvider.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemAssets
import TangemLocalization

struct AllServicesItemsProvider {
    var itemsPublisher: AnyPublisher<[AllServicesItem], Never> {
        .just(output: FeatureProvider.isAvailable(.mobileWalletMultiCreation) ? [Self.addWalletItem] : [])
    }
}

// MARK: - Items

private extension AllServicesItemsProvider {
    static var addWalletItem: AllServicesItem {
        AllServicesItem(
            id: .addWallet,
            icon: .glyph(DesignSystem.Icons.SignPlus.regular20),
            title: Localization.userWalletAddWallet,
            // [REDACTED_TODO_COMMENT]
            subtitle: "Separate funds by purpose"
        )
    }
}
