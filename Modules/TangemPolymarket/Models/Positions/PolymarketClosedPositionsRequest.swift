//
//  PolymarketClosedPositionsRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketClosedPositionsRequest: Hashable, Sendable {
    public let depositWalletAddress: String
    public let page: PolymarketPositionsPageRequest<Sort>

    public init(depositWalletAddress: String, page: PolymarketPositionsPageRequest<Sort>) {
        self.depositWalletAddress = depositWalletAddress
        self.page = page
    }
}

// MARK: - Sort

public extension PolymarketClosedPositionsRequest {
    enum Sort: String, Hashable, Sendable {
        case closedAt
        case realizedPnl
    }
}
