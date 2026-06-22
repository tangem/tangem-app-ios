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
            exchangePollingHelper: makeExchangeStatusPollingHelper(poller: exchangeStatusPoller),
            onrampPollingHelper: makeOnrampStatusPollingHelper(poller: onrampStatusPoller)
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
            userWalletId: userWalletInfo.id.stringValue,
            tokenItem: tokenItem,
            cachingExpressAPIProviderFactory: cachingExpressAPIProviderFactory,
            expressRefundedTokenHandler: expressRefundedTokenHandler
        )
    }

    private func makeOnrampStatusPoller(cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory) -> OnrampStatusPoller {
        OnrampStatusPoller(
            userWalletId: userWalletInfo.id.stringValue,
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

    private func makeExchangeStatusPollingHelper(poller: ExchangeStatusPoller) -> ExchangeStatusPollingHelper {
        ExchangeStatusPollingHelper(
            poller: poller,
            enricherFactory: transactionHistoryEnricherFactory
        )
    }

    private func makeOnrampStatusPollingHelper(poller: OnrampStatusPoller) -> OnrampStatusPollingHelper {
        OnrampStatusPollingHelper(
            poller: poller,
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
            userWalletId: userWalletInfo.id.stringValue,
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
        let exchangePollingHelper: ExchangeStatusPollingHelper
        let onrampPollingHelper: OnrampStatusPollingHelper

        fileprivate init(
            manager: PendingExpressTransactionsManager,
            exchangePollingHelper: ExchangeStatusPollingHelper,
            onrampPollingHelper: OnrampStatusPollingHelper
        ) {
            self.manager = manager
            self.exchangePollingHelper = exchangePollingHelper
            self.onrampPollingHelper = onrampPollingHelper
        }
    }
}
