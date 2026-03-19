//
//  RateLimitedMoralisTokenBalanceClient.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import BlockchainSdk

/// Decorator over `MoralisTokenBalanceClient` that throttles requests through
/// a shared `MoralisRateLimitedRequestQueue` and retries exactly once on HTTP 429.
/// Before retry, waits `retryBackoff` to reduce the chance of another 429.
final class RateLimitedMoralisTokenBalanceClient: @unchecked Sendable {
    private let client: MoralisTokenBalanceClient
    private let queue: MoralisRateLimitedRequestQueue
    private let retryBackoff: Duration

    init(
        client: MoralisTokenBalanceClient,
        queue: MoralisRateLimitedRequestQueue,
        retryBackoff: Duration = .seconds(1)
    ) {
        self.client = client
        self.queue = queue
        self.retryBackoff = retryBackoff
    }
}

// MARK: - MoralisTokenBalanceClient

extension RateLimitedMoralisTokenBalanceClient: MoralisTokenBalanceClient {
    func getTokenBalances(network: Blockchain, address: String) async throws -> [MoralisTokenBalance] {
        do {
            return try await queue.execute { [client] in
                try await client.getTokenBalances(network: network, address: address)
            }
        } catch MoralisTokenBalanceError.rateLimited {
            try await Task.sleep(for: retryBackoff)
            return try await queue.execute { [client] in
                try await client.getTokenBalances(network: network, address: address)
            }
        }
    }
}
