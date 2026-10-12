//
//  PolymarketOrderFactory.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PolymarketOrderFactory {
    public static func make(
        quote: PolymarketOrderQuote,
        assetId: String,
        depositWalletAddress: String
    ) -> PolymarketOrder {
        let notional = scaled(quote.notional)
        let shares = scaled(quote.shares)

        return PolymarketOrder(
            salt: UInt64.random(in: 1 ... Constants.maxSafeInteger),
            maker: depositWalletAddress,
            signer: depositWalletAddress,
            tokenId: assetId,
            makerAmount: quote.side == .buy ? notional : shares,
            takerAmount: quote.side == .buy ? shares : notional,
            side: quote.side,
            timestampMillis: UInt64(Date().timeIntervalSince1970 * Constants.millisecondsPerSecond),
            builder: quote.builderCode
        )
    }
}

// MARK: - Private implementation

private extension PolymarketOrderFactory {
    static func scaled(_ value: Decimal) -> String {
        var raised = value * pow(10, PolymarketCollateral.decimalCount)
        var truncated = Decimal()

        NSDecimalRound(&truncated, &raised, 0, .down)

        return NSDecimalNumber(decimal: truncated).stringValue
    }

    enum Constants {
        static let maxSafeInteger: UInt64 = 9_007_199_254_740_991
        static let millisecondsPerSecond: TimeInterval = 1000
    }
}
