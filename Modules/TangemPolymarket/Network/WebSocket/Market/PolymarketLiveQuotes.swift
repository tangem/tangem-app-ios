//
//  PolymarketLiveQuotes.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public final class PolymarketLiveQuotes: Sendable {
    private let client = PolymarketWebSocketSubscriptionClient(channel: PolymarketMarketChannel())

    public init() {}

    public func quotes(for assetIds: Set<String>) async -> AsyncStream<PolymarketOutcomeQuote> {
        await client.values(for: assetIds)
    }

    public func statusChanges() async -> AsyncStream<PolymarketWebSocketConnectionStatus> {
        await client.statusChanges()
    }
}
