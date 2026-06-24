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

        let exchangeStatusPoller = makeExchangeStatusPoller(cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory)
        let onrampStatusPoller = makeOnrampStatusPoller(cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory)

        return ExpressStatusTracking(
            manager: makePendingTransactionsManager(
                exchangeStatusPoller: exchangeStatusPoller,
                onrampStatusPoller: onrampStatusPoller,
                cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory
            ),
            pollingHelper: makeStatusPollingHelper(
                exchangeStatusPoller: exchangeStatusPoller,
                onrampStatusPoller: onrampStatusPoller
            )
        )
    }

    private func makeExchangeStatusPoller(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) -> ExchangeStatusPoller {
        let tokenEnricher = CommonTokenEnricher(
            supportedBlockchains: userWalletInfo.config.supportedBlockchains
        )

        let expressRefundedTokenHandler = CommonExpressRefundedTokenHandler(
            tokenEnricher: tokenEnricher
        )

        return ExchangeStatusPoller(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )
    }

    private func makeOnrampStatusPoller(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) -> OnrampStatusPoller {
        OnrampStatusPoller(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            expressAPIProvider: cachingExpressAPIProviderFactory.provider(
                for: userWalletInfo.id.stringValue,
                refcode: userWalletInfo.refcode
            )
        )
    }

    private func makePendingTransactionsManager(
        exchangeStatusPoller: ExchangeStatusPoller,
        onrampStatusPoller: OnrampStatusPoller,
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    ) -> PendingExpressTransactionsManager {
        let pendingExpressTransactionsManager = CommonPendingExpressTransactionsManager(
            walletModelUpdater: walletModelUpdater,
            poller: exchangeStatusPoller
        )

        let pendingOnrampTransactionsManager = makePendingOnrampTransactionsManager(
            poller: onrampStatusPoller,
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory
        )

        return CompoundPendingTransactionsManager(
            first: pendingExpressTransactionsManager,
            second: pendingOnrampTransactionsManager
        )
    }

    private func makeStatusPollingHelper(
        exchangeStatusPoller: ExchangeStatusPoller,
        onrampStatusPoller: OnrampStatusPoller
    ) -> ExpressStatusPollingHelper {
        ExpressStatusPollingHelper(
            exchangePoller: exchangeStatusPoller,
            onrampPoller: onrampStatusPoller,
            enricherFactory: transactionHistoryEnricherFactory
        )
    }

    private func makePendingOnrampTransactionsManager(
        poller: OnrampStatusPoller,
        cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory
    ) -> PendingExpressTransactionsManager {
        let expressAPIProvider = cachingExpressAPIProviderFactory.provider(
            for: userWalletInfo.id.stringValue,
            refcode: userWalletInfo.refcode
        )

        let unknownStatusRecoveryService = CommonOnrampUnknownStatusRecoveryService(
            userWalletId: userWalletInfo.id,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        return CommonPendingOnrampTransactionsManager(
            unknownStatusRecoveryService: unknownStatusRecoveryService,
            poller: poller
        )
    }
}

// MARK: - Auxiliary types

extension ExpressStatusTrackingFactory {
    struct ExpressStatusTracking {
        let manager: PendingExpressTransactionsManager
        let pollingHelper: ExpressStatusPollingHelper

        fileprivate init(
            manager: PendingExpressTransactionsManager,
            pollingHelper: ExpressStatusPollingHelper
        ) {
            self.manager = manager
            self.pollingHelper = pollingHelper
        }
    }
}
