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

        let cachingExpressAPIProviderFactory = CachingExpressAPIProviderFactory { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }

        let exchangeStatusPoller = ExchangeStatusPoller(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )

        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            walletModelUpdater: walletModelUpdater,
            poller: exchangeStatusPoller
        )

        let expressAPIProvider = cachingExpressAPIProviderFactory.provider(for: userWalletInfo.id.stringValue, refcode: userWalletInfo.refcode)
        let onrampStatusPoller = OnrampStatusPoller(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )
        let unknownStatusRecoveryService = CommonOnrampUnknownStatusRecoveryService(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        let pendingOnrampTransactionsManager = CommonPendingOnrampTransactionsManager(
            unknownStatusRecoveryService: unknownStatusRecoveryService,
            poller: onrampStatusPoller
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }
}
