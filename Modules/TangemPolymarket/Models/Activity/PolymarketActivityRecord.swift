//
//  PolymarketActivityRecord.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketActivityRecord: Hashable, Sendable, Identifiable {
    public let id: String
    public let type: PolymarketActivityType
    public let occurredAt: Date
    public let amount: Decimal
    public let transactionHash: String?
    public let market: PolymarketActivityMarket?
    public let order: PolymarketActivityOrder?
    public let redeemResult: PolymarketRedeemResult?

    public init(
        id: String,
        type: PolymarketActivityType,
        occurredAt: Date,
        amount: Decimal,
        transactionHash: String?,
        market: PolymarketActivityMarket?,
        order: PolymarketActivityOrder?,
        redeemResult: PolymarketRedeemResult?
    ) {
        self.id = id
        self.type = type
        self.occurredAt = occurredAt
        self.amount = amount
        self.transactionHash = transactionHash
        self.market = market
        self.order = order
        self.redeemResult = redeemResult
    }
}

// MARK: - Kind

public enum PolymarketActivityType: String, Hashable, Sendable, CaseIterable {
    case buy = "BUY"
    case sell = "SELL"
    case redeem = "REDEEM"
    case deposit = "DEPOSIT"
    case withdraw = "WITHDRAW"
}

public extension PolymarketActivityType {
    var isIncoming: Bool {
        switch self {
        case .deposit, .sell, .redeem: true
        case .buy, .withdraw: false
        }
    }
}

// MARK: - Claim result

public enum PolymarketRedeemResult: String, Hashable, Sendable, CaseIterable {
    case won = "WON"
    case lost = "LOST"
    case split = "SPLIT"
}

// MARK: - Page

public struct PolymarketActivityPage: Hashable, Sendable {
    public let records: [PolymarketActivityRecord]
    public let receivedCount: Int
    public let nextCursor: String?

    public init(records: [PolymarketActivityRecord], receivedCount: Int, nextCursor: String?) {
        self.records = records
        self.receivedCount = receivedCount
        self.nextCursor = nextCursor
    }
}
