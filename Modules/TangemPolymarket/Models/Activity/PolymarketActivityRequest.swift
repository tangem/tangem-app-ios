//
//  PolymarketActivityRequest.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketActivityRequest: Hashable, Sendable {
    public let depositWalletAddress: String
    public let type: PolymarketActivityType?
    public let redeemResult: PolymarketRedeemResult?
    public let limit: Int
    public let cursor: String?

    public init(
        depositWalletAddress: String,
        type: PolymarketActivityType? = nil,
        redeemResult: PolymarketRedeemResult? = nil,
        limit: Int = Constants.defaultLimit,
        cursor: String? = nil
    ) {
        self.depositWalletAddress = depositWalletAddress
        self.type = type
        self.redeemResult = redeemResult
        self.limit = min(max(limit, Constants.minLimit), Constants.maxLimit)
        self.cursor = cursor
    }
}

// MARK: - Constants

public extension PolymarketActivityRequest {
    enum Constants {
        public static let minLimit = 1
        public static let maxLimit = 100
        public static let defaultLimit = 25
    }
}
