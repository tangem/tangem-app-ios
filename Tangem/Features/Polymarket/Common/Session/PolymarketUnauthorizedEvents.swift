//
//  PolymarketUnauthorizedEvents.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket

actor PolymarketUnauthorizedEvents {
    private var subscribers = AsyncStream<String>.MulticastSubscribers<UUID>()

    nonisolated func events(walletId: String) -> AsyncStream<Void> {
        let rejectedWalletIds = AsyncStream<String>.multicast(
            with: self,
            onSubscribe: { events, id, continuation in events.subscribers.subscribe(id: id, continuation: continuation) },
            onUnsubscribe: { events, id in events.subscribers.unsubscribe(id: id) }
        )

        return AsyncStream { continuation in
            let forwarding = Task {
                for await rejectedWalletId in rejectedWalletIds where rejectedWalletId == walletId {
                    continuation.yield()
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in forwarding.cancel() }
        }
    }

    private func publish(walletId: String) {
        subscribers.yield(walletId)
    }
}

// MARK: - PolymarketUnauthorizedObserving protocol conformance

extension PolymarketUnauthorizedEvents: PolymarketUnauthorizedObserving {
    nonisolated func backendRejectedAuthorization(walletId: String) {
        Task { await publish(walletId: walletId) }
    }
}

// MARK: - Injection

private struct PolymarketUnauthorizedEventsKey: InjectionKey {
    static var currentValue = PolymarketUnauthorizedEvents()
}

extension InjectedValues {
    var polymarketUnauthorizedEvents: PolymarketUnauthorizedEvents {
        get { Self[PolymarketUnauthorizedEventsKey.self] }
        set { Self[PolymarketUnauthorizedEventsKey.self] = newValue }
    }
}
