//
//  ExpressStatusTrackingFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressStatusTrackingFactory {
    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let walletModelUpdater: (any WalletModelUpdater)?
    let transactionHistoryEnricherFactory: TransactionHistoryExpressDataEnriching.Factory

    func makeExpressStatusTracking() -> ExpressStatusTracking {
        let cachingExpressAPIProviderFactory = CachingExpressAPIProviderFactory { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }

        let statusPoller = makeStatusPoller(cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory)

        return ExpressStatusTracking(
            manager: makePendingTransactionsManager(
                poller: statusPoller,
                cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory
            ),
            pollingHelper: makeStatusPollingHelper(
                poller: statusPoller
            )
        )
    }

    private func makeStatusPoller(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) -> ExchangeStatusPoller {
        let tokenEnricher = CommonTokenEnricher(
            supportedBlockchains: userWalletInfo.config.supportedBlockchains
        )

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            tokenEnricher: tokenEnricher
        )

        return ExchangeStatusPoller(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )
    }

    private func makePendingTransactionsManager(
        poller: ExchangeStatusPoller,
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    ) -> PendingExpressTransactionsManager {
        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            walletModelUpdater: walletModelUpdater,
            poller: poller
        )

        let pendingOnrampTransactionsManager = makePendingOnrampTransactionsManager(
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }

    private func makeStatusPollingHelper(poller: ExchangeStatusPoller) -> ExchangeStatusPollingHelper {
        ExchangeStatusPollingHelper(
            poller: poller,
            enricherFactory: transactionHistoryEnricherFactory
        )
    }

    private func makePendingOnrampTransactionsManager(
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    ) -> PendingExpressTransactionsManager {
        let expressAPIProvider = cachingExpressAPIProviderFactory.provider(
            for: userWalletInfo.id.stringValue,
            refcode: userWalletInfo.refcode
        )

        let onrampStatusPoller = OnrampStatusPoller(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        let unknownStatusRecoveryService = CommonOnrampUnknownStatusRecoveryService(
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        return CommonPendingOnrampTransactionsManager(
            unknownStatusRecoveryService: unknownStatusRecoveryService,
            poller: onrampStatusPoller
        )
    }
}

// MARK: - Auxiliary types

extension ExpressStatusTrackingFactory {
    struct ExpressStatusTracking {
        let manager: PendingExpressTransactionsManager
        let pollingHelper: ExchangeStatusPollingHelper

        fileprivate init(
            manager: PendingExpressTransactionsManager,
            pollingHelper: ExchangeStatusPollingHelper
        ) {
            self.manager = manager
            self.pollingHelper = pollingHelper
        }
    }
}
