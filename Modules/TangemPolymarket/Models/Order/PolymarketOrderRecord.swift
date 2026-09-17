//
//  PolymarketOrderRecord.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// What the exchange knows about an order after it was accepted. A market that delays its trading
/// answers the placement with nothing but an id, and this is the only way to learn how it ended.
public struct PolymarketOrderRecord: Hashable, Sendable {
    public let status: PolymarketOrderRecordStatus
    public let originalSize: Decimal
    public let matchedSize: Decimal
    public let price: Decimal

    public init(status: PolymarketOrderRecordStatus, originalSize: Decimal, matchedSize: Decimal, price: Decimal) {
        self.status = status
        self.originalSize = originalSize
        self.matchedSize = matchedSize
        self.price = price
    }
}

// MARK: - Status

public enum PolymarketOrderRecordStatus: String, Hashable, Sendable {
    case live = "ORDER_STATUS_LIVE"
    case matched = "ORDER_STATUS_MATCHED"
    case canceled = "ORDER_STATUS_CANCELED"
    case canceledMarketResolved = "ORDER_STATUS_CANCELED_MARKET_RESOLVED"
    case invalid = "ORDER_STATUS_INVALID"

    case unknown
}

// MARK: - Decodable protocol conformance

extension PolymarketOrderRecordStatus: Decodable {
    public init(from decoder: any Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PolymarketOrderRecordStatus(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Convenience extensions

public extension PolymarketOrderRecord {
    /// The exchange reports sizes in the collateral's base units.
    var matchedShares: Decimal {
        matchedSize / pow(10, PolymarketCollateral.decimalCount)
    }

    var executedAmount: Decimal {
        (matchedShares * price).rounded(scale: 2, roundingMode: .plain)
    }

    var isFullyMatched: Bool {
        matchedSize >= originalSize
    }
}
