//
//  ExpressStatusPollingHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemExpress

/// A simple helper that subscribes to express status polling and asynchronously updates the transaction history (v2) from it.
final class ExpressStatusPollingHelper {
    private let exchangePoller: (any ExpressStatusPolling<ExchangeStatusPollIteration>)?
    private let onrampPoller: (any ExpressStatusPolling<OnrampStatusPollIteration>)?
    private let enricherFactory: TransactionHistoryExpressDataEnriching.Factory
    private var subscriptions: [Cancellable] = []

    init(
        exchangePoller: (any ExpressStatusPolling<ExchangeStatusPollIteration>)?,
        onrampPoller: (any ExpressStatusPolling<OnrampStatusPollIteration>)?,
        enricherFactory: @escaping TransactionHistoryExpressDataEnriching.Factory
    ) {
        self.exchangePoller = exchangePoller
        self.onrampPoller = onrampPoller
        self.enricherFactory = enricherFactory

        bind()
    }

    deinit {
        subscriptions.forEach { $0.cancel() }
    }

    private func bind() {
        if let exchangePoller {
            subscriptions.append(
                exchangePoller.subscribe { [weak self] iteration in
                    self?.enrichExchange(iteration.polled)
                }
            )
        }

        if let onrampPoller {
            subscriptions.append(
                onrampPoller.subscribe { [weak self] iteration in
                    self?.enrichOnramp(iteration.polled)
                }
            )
        }
    }

    private func enrichExchange(_ transactions: [ExchangeTransaction]) {
        enrich(transactions) { enricher, transaction in
            await enricher.enrich(with: transaction)
        }
    }

    private func enrichOnramp(_ transactions: [OnrampTransaction]) {
        enrich(transactions) { enricher, transaction in
            await enricher.enrich(with: transaction)
        }
    }

    private func enrich<Transaction>(
        _ transactions: [Transaction],
        enrichItem: @escaping (TransactionHistoryExpressDataEnriching, Transaction) async -> Void
    ) {
        // [REDACTED_TODO_COMMENT]
        guard transactions.isNotEmpty else {
            return
        }

        runTask { [enricherFactory] in
            guard let enricher = await enricherFactory() else {
                return
            }

            // [REDACTED_TODO_COMMENT]
            for transaction in transactions {
                await enrichItem(enricher, transaction)
            }
        }
    }
}

// MARK: - Convenience initializers

extension ExpressStatusPollingHelper {
    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "To be removed, do not use")
    convenience init(enricherFactory: @escaping TransactionHistoryExpressDataEnriching.Factory) {
        self.init(exchangePoller: nil, onrampPoller: nil, enricherFactory: enricherFactory)
    }

    convenience init(
        exchangePoller: any ExpressStatusPolling<ExchangeStatusPollIteration>,
        enricherFactory: @escaping TransactionHistoryExpressDataEnriching.Factory
    ) {
        self.init(exchangePoller: exchangePoller, onrampPoller: nil, enricherFactory: enricherFactory)
    }

    convenience init(
        onrampPoller: any ExpressStatusPolling<OnrampStatusPollIteration>,
        enricherFactory: @escaping TransactionHistoryExpressDataEnriching.Factory
    ) {
        self.init(exchangePoller: nil, onrampPoller: onrampPoller, enricherFactory: enricherFactory)
    }
}
