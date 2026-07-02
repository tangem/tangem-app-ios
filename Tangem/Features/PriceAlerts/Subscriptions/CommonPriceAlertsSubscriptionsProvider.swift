//
//  CommonPriceAlertsSubscriptionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonPriceAlertsSubscriptionsProvider {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let walletId: String
    private let stateStore = PriceAlertsSubscriptionsStateStore()
    private let subscriptionsSubject = CurrentValueSubject<RemotePriceAlertsSubscriptions, Never>(.loading)

    nonisolated init(walletId: String) {
        self.walletId = walletId
    }
}

// MARK: - PriceAlertsSubscriptionsProvider

extension CommonPriceAlertsSubscriptionsProvider: PriceAlertsSubscriptionsProvider {
    var subscriptionsPublisher: AnyPublisher<RemotePriceAlertsSubscriptions, Never> {
        subscriptionsSubject.eraseToAnyPublisher()
    }

    var subscriptions: RemotePriceAlertsSubscriptions {
        subscriptionsSubject.value
    }

    func isSubscribed(tokenId: PriceAlertTokenId) -> Bool {
        subscriptions.isSubscribed(tokenId: tokenId)
    }

    func fetch() async throws {
        do {
            let tokenIds = try await tangemApiService.priceAlertsSubscriptions(userWalletId: walletId)

            try Task.checkCancellation()

            guard let newSubscriptions = await stateStore.applyFetchResponse(tokenIds) else {
                return
            }

            await publish(newSubscriptions)
        } catch {
            if error is CancellationError || Task.isCancelled {
                // The fetch was cancelled (e.g. the wallet was switched); do not turn loading into `.failed`.
                throw error
            }

            PriceAlertsSubscriptionsLogger.error("Failed to fetch price alerts subscriptions", error: error)
            if let failedSubscriptions = await stateStore.applyFetchFailure() {
                await publish(failedSubscriptions)
            }

            throw error
        }
    }

    func subscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws {
        try await mutate(tokenId: tokenId, walletIds: walletIds, isSubscribe: true)
    }

    func unsubscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws {
        try await mutate(tokenId: tokenId, walletIds: walletIds, isSubscribe: false)
    }
}

// MARK: - Helpers

private extension CommonPriceAlertsSubscriptionsProvider {
    func mutate(tokenId: PriceAlertTokenId, walletIds: [String], isSubscribe: Bool) async throws {
        guard let optimisticSubscriptions = await stateStore.beginWrite(tokenId: tokenId, isSubscribe: isSubscribe) else {
            throw PriceAlertsSubscriptionsError.writeRejected
        }

        await publish(optimisticSubscriptions)

        do {
            if isSubscribe {
                try await tangemApiService.subscribeToPriceAlerts(userWalletIds: walletIds, tokenId: tokenId)
            } else {
                try await tangemApiService.unsubscribeFromPriceAlerts(userWalletIds: walletIds, tokenId: tokenId)
            }

            try Task.checkCancellation()

            _ = await stateStore.finishWrite(tokenId: tokenId, isSubscribe: isSubscribe, isSuccess: true)
            scheduleReconciliationFetchIfNeeded()
        } catch {
            PriceAlertsSubscriptionsLogger.error("Failed to mutate price alerts subscription, rolling back", error: error)
            // Roll back on both failure and cancellation: the optimistic delta is unconfirmed, and a
            // reconciliation fetch will resolve the true state.
            if let rolledBackSubscriptions = await stateStore.finishWrite(tokenId: tokenId, isSubscribe: isSubscribe, isSuccess: false) {
                await publish(rolledBackSubscriptions)
            }

            scheduleReconciliationFetchIfNeeded()
            throw error
        }
    }

    @MainActor
    func publish(_ subscriptions: RemotePriceAlertsSubscriptions) {
        subscriptionsSubject.send(subscriptions)
    }

    /// Fire-and-forget re-fetch of the snapshot dropped during a write, now that writes have settled.
    func scheduleReconciliationFetchIfNeeded() {
        runTask(in: self) { provider in
            guard await provider.stateStore.consumePendingFetchReconciliation() else {
                return
            }

            try? await provider.fetch()
        }
    }
}
