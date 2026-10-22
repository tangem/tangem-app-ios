//
//  PolymarketLiveGames.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public final class PolymarketLiveGames: Sendable {
    private let client = PolymarketWebSocketSubscriptionClient(channel: PolymarketSportsChannel())

    public init() {}

    public func games(for gameIds: Set<Int>) async -> AsyncStream<PolymarketLiveGame> {
        await client.values(for: gameIds)
    }

    public func statusChanges() async -> AsyncStream<PolymarketWebSocketConnectionStatus> {
        await client.statusChanges()
    }
}
