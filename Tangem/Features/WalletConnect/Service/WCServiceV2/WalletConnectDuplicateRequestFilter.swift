//
//  WalletConnectDuplicateRequestFilter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import ReownWalletKit

final actor WalletConnectDuplicateRequestFilter {
    private var requestToReceivedDate: [StableRequestFootprint: Date] = [:]
    private let window: TimeInterval

    init(window: TimeInterval = 120) {
        self.window = window
    }

    func isProcessingAllowed(for request: ReownWalletKit.Request) -> Bool {
        removeExpiredRecentRequests()

        let requestFootprint = StableRequestFootprint(from: request)

        defer {
            requestToReceivedDate[requestFootprint] = Date()
        }

        guard let potentialDuplicateRequestReceivedDate = requestToReceivedDate[requestFootprint] else {
            return true
        }

        let enoughTimePassedSinceLastRequest = Date().timeIntervalSince(potentialDuplicateRequestReceivedDate) > window
        return enoughTimePassedSinceLastRequest
    }

    private func removeExpiredRecentRequests() {
        requestToReceivedDate.removeAll(
            where: {
                let isExpired = Date().timeIntervalSince($0.value) > window
                return isExpired
            }
        )
    }
}

extension WalletConnectDuplicateRequestFilter {
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
