//
//  OnrampStatusTrackingFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct OnrampStatusTrackingFactory {
    let userWalletId: UserWalletId
    let tokenItem: TokenItem
    let transactionHistoryEnricherFactory: TransactionHistoryExpressDataEnriching.Factory

    func makeOnrampStatusTracking(expressAPIProvider: ExpressAPIProvider) -> OnrampStatusTracking {
        let onrampStatusPoller = makeOnrampStatusPoller(expressAPIProvider: expressAPIProvider)

        return OnrampStatusTracking(
            manager: makePendingOnrampTransactionsManager(
                poller: onrampStatusPoller,
                expressAPIProvider: expressAPIProvider
            ),
            pollingHelper: makeOnrampStatusPollingHelper(
                poller: onrampStatusPoller
            )
        )
    }

    private func makeOnrampStatusPoller(expressAPIProvider: ExpressAPIProvider) -> OnrampStatusPoller {
        OnrampStatusPoller(
            userWalletId: userWalletId,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )
    }

    private func makePendingOnrampTransactionsManager(
        poller: OnrampStatusPoller,
        expressAPIProvider: ExpressAPIProvider
    ) -> PendingExpressTransactionsManager {
        let unknownStatusRecoveryService = CommonOnrampUnknownStatusRecoveryService(
            userWalletId: userWalletId,
            tokenItem: tokenItem,
            expressAPIProvider: expressAPIProvider
        )

        return CommonPendingOnrampTransactionsManager(
            unknownStatusRecoveryService: unknownStatusRecoveryService,
            poller: poller
        )
    }

    private func makeOnrampStatusPollingHelper(poller: OnrampStatusPoller) -> ExpressStatusPollingHelper {
        ExpressStatusPollingHelper(
            onrampPoller: poller,
            enricherFactory: transactionHistoryEnricherFactory
        )
    }
}

// MARK: - Auxiliary types

extension OnrampStatusTrackingFactory {
    struct OnrampStatusTracking {
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
