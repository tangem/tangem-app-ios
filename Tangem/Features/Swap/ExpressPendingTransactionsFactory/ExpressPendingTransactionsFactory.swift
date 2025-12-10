//
//  ExpressPendingTransactionsFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressPendingTransactionsFactory {
    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let walletModelUpdater: (any WalletModelUpdater)?

    func makePendingExpressTransactionsManager() -> any PendingExpressTransactionsManager {
        let tokenEnricher = CommonTokenEnricher(
            supportedBlockchains: userWalletInfo.config.supportedBlockchains
        )

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            tokenEnricher: tokenEnricher
        )

        let expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            walletModelUpdater: walletModelUpdater,
            expressAPIProvider: expressAPIProvider,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }
}
