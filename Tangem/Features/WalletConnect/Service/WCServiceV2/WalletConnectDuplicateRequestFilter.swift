//
//  WalletConnectDuplicateRequestFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

/// Filters out duplicate ``ReownWalletKit.Request`` within a given time window.
///
/// Each request updates its last-seen timestamp, so repeated duplicates keep the interval window active.
actor WalletConnectDuplicateRequestFilter {
    private let requiredIntervalBetweenDuplicateRequests: TimeInterval
    private let currentDateProvider: () -> Date

    private var requestToReceivedDate: [StableRequestFootprint: Date] = [:]

    /// Creates a duplicate request filter.
    /// - Parameters:
    ///   - requiredIntervalBetweenDuplicateRequests: Minimum time interval to allow processing the same request footprint again.
    ///   Defaults to 120 seconds.
    ///   - currentDateProvider: Date provider. Defaults to ``Date/init()``.
    init(
        requiredIntervalBetweenDuplicateRequests: TimeInterval = 120,
        currentDateProvider: @escaping () -> Date = Date.init
    ) {
        self.requiredIntervalBetweenDuplicateRequests = requiredIntervalBetweenDuplicateRequests
        self.currentDateProvider = currentDateProvider
    }

    /// Removes the footprint for the given request, allowing it to be processed again immediately.
    ///
    /// Call this after a request has been cancelled or successfully handled to ensure
    /// that retry attempts from the dApp are not blocked by the duplicate filter.
    func removeFootprint(for request: ReownWalletKit.Request) {
        let footprint = StableRequestFootprint(from: request)
        requestToReceivedDate[footprint] = nil
    }

    /// Returns `true` if processing is allowed for the request, `false` if it is considered a recent duplicate.
    func isProcessingAllowed(for request: ReownWalletKit.Request) -> Bool {
        let currentDate = currentDateProvider()
        removeExpiredRecentRequests(currentDate)

        let requestFootprint = StableRequestFootprint(from: request)

        defer {
            requestToReceivedDate[requestFootprint] = currentDate
        }

        guard let potentialDuplicateRequestReceivedDate = requestToReceivedDate[requestFootprint] else {
            return true
        }

        let timePassedSinceLastRequest = currentDate.timeIntervalSince(potentialDuplicateRequestReceivedDate)
        let isEnough = timePassedSinceLastRequest >= requiredIntervalBetweenDuplicateRequests

        return isEnough
    }

    private func removeExpiredRecentRequests(_ currentDate: Date) {
        requestToReceivedDate.removeAll(
            where: {
                let isExpired = currentDate.timeIntervalSince($0.value) > requiredIntervalBetweenDuplicateRequests
                return isExpired
            }
        )
    }
}

extension WalletConnectDuplicateRequestFilter {
    /// Footprint of a ``ReownWalletKit.Request`` without unstable properties. Suitable for hash value comparison.
    private struct StableRequestFootprint: Hashable {
        let topic: String
        let method: String
        let params: AnyCodable
        let chainId: ReownWalletKit.Blockchain

        init(from request: ReownWalletKit.Request) {
            topic = request.topic
            method = request.method
            params = request.params
            chainId = request.chainId
        }
    }
}
