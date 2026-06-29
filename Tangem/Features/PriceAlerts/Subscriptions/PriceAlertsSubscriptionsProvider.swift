//
//  PriceAlertsSubscriptionsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Single source of truth for a wallet's Price Alerts subscriptions, feeding the coin-screen bell and the
/// watchlist. Owns the optimistic-update / rollback / reconciliation flow.
protocol PriceAlertsSubscriptionsProvider: AnyObject {
    var subscriptionsPublisher: AnyPublisher<RemotePriceAlertsSubscriptions, Never> { get }
    var subscriptions: RemotePriceAlertsSubscriptions { get }

    func isSubscribed(tokenId: PriceAlertTokenId) -> Bool
    func fetch() async throws
    func subscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws
    func unsubscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws
}

enum PriceAlertsSubscriptionsError: Error {
    /// Subscription list not loaded yet, or another write for the same coin is in flight.
    case writeRejected
}
