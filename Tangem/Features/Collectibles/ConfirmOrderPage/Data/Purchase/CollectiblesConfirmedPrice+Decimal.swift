//
//  CollectiblesConfirmedPrice+Decimal.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

extension CollectiblesConfirmedPrice {
    init(price: Decimal, platformFee: Decimal) throws {
        self.init(amount: try Self.baseUnits(of: price), feeAmount: try Self.baseUnits(of: platformFee))
    }
}

// MARK: - Private logic

private extension CollectiblesConfirmedPrice {
    static func baseUnits(of amount: Decimal) throws -> UInt64 {
        let units = amount
            .moveRight(decimals: CollectiblesChainEnvironment.usdcTokenItem.decimalCount)
            .rounded(roundingMode: .plain)

        guard units >= 0, units <= Decimal(UInt64.max) else {
            throw CollectiblesPackPurchaseError.invalidPrice
        }

        return units.uint64Value
    }
}
