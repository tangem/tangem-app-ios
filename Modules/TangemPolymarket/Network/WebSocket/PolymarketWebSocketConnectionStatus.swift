//
//  PolymarketWebSocketConnectionStatus.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum PolymarketWebSocketConnectionStatus: Hashable, Sendable {
    case idle
    case connecting
    case connected
    case waitingToReconnect
    case stopped
}
