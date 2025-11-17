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
    let walletModel: any WalletModel

    func makePendingExpressTransactionsManager() -> any PendingExpressTransactionsManager {
        let tokenLoader = CommonTokenEnricher(
            supportedBlockchains: userWalletInfo.config.supportedBlockchains
        )

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            tokenLoader: tokenLoader
        )

        let expressAPIProvider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            walletModel: walletModel,
            expressAPIProvider: expressAPIProvider,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            userWalletId: userWalletInfo.id.stringValue,
            walletModel: walletModel,
            expressAPIProvider: expressAPIProvider
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }
}
