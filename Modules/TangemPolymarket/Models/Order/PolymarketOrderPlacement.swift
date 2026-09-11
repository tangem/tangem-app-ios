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
    public let status: String?

    public let makingAmount: Decimal?
    public let takingAmount: Decimal?

    public let transactionHashes: [String]

    public init(
        orderId: String?,
        status: String?,
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
        status?.trimmed().caseInsensitiveCompare(Constants.matchedStatus) == .orderedSame
    }

    var isMatchedWithoutFill: Bool {
        isMatched && (takingAmount ?? 0) <= 0
    }
}

private extension PolymarketOrderPlacement {
    enum Constants {
        static let matchedStatus = "matched"
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
