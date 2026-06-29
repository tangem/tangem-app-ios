//
//  PriceAlertsSubscriptionsStateStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Subscribe/unsubscribe are independent per-`tokenId` operations (last-write-wins), so writes are
/// single-flight **per token** (not global as in notification-preferences) and a failed write reverses
/// only its own delta. A fetch arriving mid-write is deferred so it can't clobber an unconfirmed write.
actor PriceAlertsSubscriptionsStateStore {
    private(set) var subscriptions: RemotePriceAlertsSubscriptions = .loading
    private var lastConfirmed: RemotePriceAlertsSubscriptions = .loading

    private var inFlightTokenIds: Set<PriceAlertTokenId> = []
    private var pendingFetchReconciliation = false

    func applyFetchResponse(_ tokenIds: [PriceAlertTokenId]) -> RemotePriceAlertsSubscriptions? {
        // Applying a server snapshot now would clobber optimistic writes that haven't settled yet.
        // Defer it and remember to re-fetch once the in-flight writes complete.
        guard inFlightTokenIds.isEmpty else {
            pendingFetchReconciliation = true
            return nil
        }

        let new = RemotePriceAlertsSubscriptions(tokenIds: tokenIds)
        subscriptions = new
        lastConfirmed = new
        pendingFetchReconciliation = false
        return new
    }

    func applyFetchFailure() -> RemotePriceAlertsSubscriptions? {
        guard case .loading = subscriptions.state else {
            return nil
        }

        let failed = RemotePriceAlertsSubscriptions(state: .failed)
        subscriptions = failed
        return failed
    }

    func consumePendingFetchReconciliation() -> Bool {
        guard pendingFetchReconciliation, inFlightTokenIds.isEmpty else {
            return false
        }

        pendingFetchReconciliation = false
        return true
    }

    /// Returns the optimistic snapshot, or `nil` if refused (set not loaded, or a write for this coin is in flight).
    func beginWrite(tokenId: PriceAlertTokenId, isSubscribe: Bool) -> RemotePriceAlertsSubscriptions? {
        guard case .ready = subscriptions.state,
              !inFlightTokenIds.contains(tokenId) else {
            return nil
        }

        inFlightTokenIds.insert(tokenId)

        var optimistic = subscriptions
        optimistic.setSubscribed(isSubscribe, tokenId: tokenId)
        subscriptions = optimistic

        return optimistic
    }

    /// On failure, reverses only this token's optimistic delta (concurrent writes on other tokens are kept)
    /// and returns the rolled-back snapshot to publish.
    func finishWrite(tokenId: PriceAlertTokenId, isSubscribe: Bool, isSuccess: Bool) -> RemotePriceAlertsSubscriptions? {
        inFlightTokenIds.remove(tokenId)

        guard !isSuccess else {
            lastConfirmed.setSubscribed(isSubscribe, tokenId: tokenId)
            return nil
        }

        var rolledBack = subscriptions
        rolledBack.setSubscribed(!isSubscribe, tokenId: tokenId)
        subscriptions = rolledBack
        return rolledBack
    }
}
