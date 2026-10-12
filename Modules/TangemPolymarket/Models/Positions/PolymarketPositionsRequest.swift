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
    public let sort: Sort
    public let ascending: Bool
    public let limit: Int
    public let offset: Int

    public init(
        depositWalletAddress: String,
        sort: Sort = .endDate,
        ascending: Bool = true,
        limit: Int = 10,
        offset: Int = 0
    ) {
        self.depositWalletAddress = depositWalletAddress
        self.sort = sort
        self.ascending = ascending
        self.limit = limit
        self.offset = offset
    }
}

// MARK: - Sort

public extension PolymarketPositionsRequest {
    enum Sort: String, Hashable, Sendable {
        case endDate
        case initialValue
        case size
        case avgPrice
        case title
    }
}
