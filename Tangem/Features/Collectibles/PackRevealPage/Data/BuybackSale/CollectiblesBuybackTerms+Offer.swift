//
//  CollectiblesBuybackTerms+Offer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

extension CollectiblesBuybackTerms {
    init(nftAddress: String, offer: CollectiblesBuybackOffer) throws {
        // [REDACTED_TODO_COMMENT]
        self.init(nftAddress: nftAddress, minimumPayoutInBaseUnits: try Self.baseUnits(of: offer.amount))
    }
}

// MARK: - Private logic

private extension CollectiblesBuybackTerms {
    static func baseUnits(of amount: Decimal) throws -> UInt64 {
        let units = amount
            .moveRight(decimals: CollectiblesChainEnvironment.usdcTokenItem.decimalCount)
            .rounded(roundingMode: .plain)

        guard units > 0, units <= Decimal(UInt64.max) else {
            throw CollectiblesBuybackSaleError.failed
        }

        return units.uint64Value
    }
}
