//
//  PolymarketDepositsScan.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketDepositsScan: Hashable, Sendable {
    public let state: State
    public let retryAfter: TimeInterval

    public init(state: State, retryAfter: TimeInterval) {
        self.state = state
        self.retryAfter = retryAfter
    }
}

// MARK: - State

public extension PolymarketDepositsScan {
    enum State: String, Hashable, Sendable {
        case scanning = "SCANNING"
        case unknown
    }
}
