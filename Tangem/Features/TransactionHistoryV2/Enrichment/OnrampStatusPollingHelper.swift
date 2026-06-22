//
//  OnrampStatusPollingHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress

/// A simple helper that subscribes to onramp status polling and asynchronously updates the transaction history (v2) from it.
final class OnrampStatusPollingHelper {
    private let poller: any ExpressStatusPolling<OnrampStatusPollIteration>
    private let enricherFactory: TransactionHistoryExpressDataEnriching.Factory
    private var subscription: Cancellable?

    init(
        poller: any ExpressStatusPolling<OnrampStatusPollIteration>,
        enricherFactory: @escaping TransactionHistoryExpressDataEnriching.Factory
    ) {
        self.poller = poller
        self.enricherFactory = enricherFactory

        bind()
    }

    deinit {
        subscription?.cancel()
    }

    private func bind() {
        subscription = poller.subscribe { [weak self] iteration in
            self?.enrich(iteration)
        }
    }

    private func enrich(_ iteration: OnrampStatusPollIteration) {
        // [REDACTED_TODO_COMMENT]
        let transactions = iteration.polled

        guard transactions.isNotEmpty else {
            return
        }

        runTask { [enricherFactory] in
            guard let enricher = await enricherFactory() else {
                return
            }

            // [REDACTED_TODO_COMMENT]
            for transaction in transactions {
                await enricher.enrich(with: transaction)
            }
        }
    }
}
