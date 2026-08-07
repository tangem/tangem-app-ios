//
//  PriceAlertsSubscriptionsProviderStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class PriceAlertsSubscriptionsProviderStub: PriceAlertsSubscriptionsProvider {
    // MARK: - Private Properties

    private let subscriptionsSubject = CurrentValueSubject<RemotePriceAlertsSubscriptions, Never>(.loading)

    /// In-memory store that acts as the "server" state. Populated on first `fetch` call.
    private var serverTokenIds: Set<PriceAlertTokenId>?

    private static let sampleTokenIds: [PriceAlertTokenId] = ["bitcoin", "ethereum", "tether", "solana"]
    private static let simulatedNetworkDelay: Duration = .milliseconds(500)

    // MARK: - PriceAlertsSubscriptionsProvider

    var subscriptionsPublisher: AnyPublisher<RemotePriceAlertsSubscriptions, Never> {
        subscriptionsSubject.eraseToAnyPublisher()
    }

    var subscriptions: RemotePriceAlertsSubscriptions {
        subscriptionsSubject.value
    }

    nonisolated init() {}

    func isSubscribed(tokenId: PriceAlertTokenId) -> Bool {
        subscriptions.isSubscribed(tokenId: tokenId)
    }

    func fetch() async throws {
        try await Task.sleep(for: Self.simulatedNetworkDelay)

        if serverTokenIds == nil {
            serverTokenIds = Self.makeRandomTokenIds()
        }

        subscriptionsSubject.send(RemotePriceAlertsSubscriptions(tokenIds: Array(serverTokenIds!)))
    }

    func subscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws {
        try await mutate(tokenId: tokenId, isSubscribe: true)
    }

    func unsubscribe(tokenId: PriceAlertTokenId, walletIds: [String]) async throws {
        try await mutate(tokenId: tokenId, isSubscribe: false)
    }
}

// MARK: - Private Helpers

private extension PriceAlertsSubscriptionsProviderStub {
    func mutate(tokenId: PriceAlertTokenId, isSubscribe: Bool) async throws {
        let snapshot = subscriptionsSubject.value
        let serverSnapshot = serverTokenIds

        var optimistic = snapshot
        optimistic.setSubscribed(isSubscribe, tokenId: tokenId)
        subscriptionsSubject.send(optimistic)
        setServerSubscription(isSubscribe, tokenId: tokenId)

        do {
            try await Task.sleep(for: Self.simulatedNetworkDelay)
        } catch {
            // Rollback on cancellation
            subscriptionsSubject.send(snapshot)
            serverTokenIds = serverSnapshot
            throw error
        }
    }

    /// Seeds the in-memory "server" state on first write so optimistic updates aren't dropped before the
    /// first `fetch`, and persists the change into it.
    func setServerSubscription(_ isSubscribe: Bool, tokenId: PriceAlertTokenId) {
        var tokenIds = serverTokenIds ?? Self.makeRandomTokenIds()
        if isSubscribe {
            tokenIds.insert(tokenId)
        } else {
            tokenIds.remove(tokenId)
        }
        serverTokenIds = tokenIds
    }

    static func makeRandomTokenIds() -> Set<PriceAlertTokenId> {
        Set(sampleTokenIds.filter { _ in Bool.random() })
    }
}
