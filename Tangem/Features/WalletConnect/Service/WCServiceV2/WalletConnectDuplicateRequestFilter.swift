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

    /// Returns `true` if processing is allowed for the request, `false` if it is considered a recent duplicate.
    func isProcessingAllowed(for request: ReownWalletKit.Request) -> Bool {
        removeExpiredRecentRequests()

        let requestFootprint = StableRequestFootprint(from: request)

        defer {
            requestToReceivedDate[requestFootprint] = currentDateProvider()
        }

        guard let potentialDuplicateRequestReceivedDate = requestToReceivedDate[requestFootprint] else {
            return true
        }

        let timePassedSinceLastRequest = currentDateProvider().timeIntervalSince(potentialDuplicateRequestReceivedDate)
        let isEnough = timePassedSinceLastRequest >= requiredIntervalBetweenDuplicateRequests

        return isEnough
    }

    private func removeExpiredRecentRequests() {
        requestToReceivedDate.removeAll(
            where: {
                let isExpired = currentDateProvider().timeIntervalSince($0.value) > requiredIntervalBetweenDuplicateRequests
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
