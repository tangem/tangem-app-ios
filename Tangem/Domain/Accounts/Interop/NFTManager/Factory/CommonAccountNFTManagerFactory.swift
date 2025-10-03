//
//  CommonAccountNFTManagerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemNFT
import TangemFoundation

struct CommonAccountNFTManagerFactory {
    private let analytics: NFTAnalytics.Error

    init(analytics: NFTAnalytics.Error) {
        self.analytics = analytics
    }
}

// MARK: - AccountNFTManagerFactory protocol conformance

extension CommonAccountNFTManagerFactory: AccountNFTManagerFactory {
    func makeNFTManager(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager
    ) -> any NFTManager {
        CommonNFTManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            analytics: analytics
        )
    }
}
