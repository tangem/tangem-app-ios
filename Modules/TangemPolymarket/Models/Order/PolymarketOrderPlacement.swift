//
//  PolymarketOrderPlacement.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public struct PolymarketOrderPlacement: Hashable, Sendable {
    public let orderId: String?
    public let status: PolymarketOrderPlacementStatus

    public let makingAmount: Decimal?
    public let takingAmount: Decimal?

    public let transactionHashes: [String]

    public init(
        orderId: String?,
        status: PolymarketOrderPlacementStatus,
        makingAmount: Decimal?,
        takingAmount: Decimal?,
        transactionHashes: [String]
    ) {
        self.orderId = orderId
        self.status = status
        self.makingAmount = makingAmount
        self.takingAmount = takingAmount
        self.transactionHashes = transactionHashes
    }
}

public extension PolymarketOrderPlacement {
    var isMatched: Bool {
        status == .matched
    }

    var isMatchedWithoutFill: Bool {
        isMatched && (takingAmount ?? 0) <= 0
    }
}

// MARK: - Status

/// A market that delays its trading answers `delayed` and fills nothing yet — the order has to be read
/// back by its id to learn how it ended.
public enum PolymarketOrderPlacementStatus: Hashable, Sendable {
    case matched
    case delayed
    case other(String?)

    public init(rawValue: String?) {
        switch rawValue?.trimmed().lowercased() {
        case "matched": self = .matched
        case "delayed": self = .delayed
        case let value: self = .other(value)
        }
    }
}

// MARK: - Error

public enum PolymarketOrderPlacementError: Error {
    case notSent(underlying: Error)
    case rejected(message: String?)
    case noLiquidity(message: String?)

    case ambiguous(underlying: Error)
}

public extension PolymarketOrderPlacementError {
    var isAmbiguous: Bool {
        if case .ambiguous = self { return true }
        return false
    }
}

// MARK: - A delayed order, once it settled

public extension PolymarketOrderPlacement {
    /// The exchange answers a delayed order with nothing but an id and reports the fill only when the
    /// order is read back, in shares and a price rather than in the two leg amounts. Both legs are
    /// restated here so every screen downstream reads a settled delayed order the way it reads a
    /// matched one.
    static func settled(_ record: PolymarketOrderRecord, orderId: String, side: PolymarketOrderSide) -> Self {
        let shares = record.matchedShares
        let money = record.executedAmount

        return PolymarketOrderPlacement(
            orderId: orderId,
            status: .matched,
            makingAmount: side == .buy ? money : shares,
            takingAmount: side == .buy ? shares : money,
            transactionHashes: []
        )
    }
}
