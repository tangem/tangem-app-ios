//
//  PolymarketPositionsRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketPositionsRequest: Hashable, Sendable {
    public let depositWalletAddress: String
    public let page: PolymarketPositionsPageRequest<Sort>

    public init(depositWalletAddress: String, page: PolymarketPositionsPageRequest<Sort>) {
        self.depositWalletAddress = depositWalletAddress
        self.page = page
    }
}

// MARK: - Sort

public extension PolymarketPositionsRequest {
    enum Sort: String, Hashable, Sendable {
        case currentValue
        case price
        case size
        case unrealizedPnl
        case realizedPnl
        case totalPnl
        case lastActivity
    }
}
