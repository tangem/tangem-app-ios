//
//  CollectiblesBuybackTermsOfferTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemCollectibles
@testable import Tangem

@Suite("CollectiblesBuybackTerms+Offer")
struct CollectiblesBuybackTermsOfferTests {
    @Test("The shown price becomes the payout floor in USDC base units", arguments: Self.priceArguments)
    func mapsPriceToBaseUnits(amount: String, units: UInt64) throws {
        let terms = try CollectiblesBuybackTerms(nftAddress: "nft-1", offer: Self.offer(amount))

        #expect(terms.nftAddress == "nft-1")
        #expect(terms.minimumPayoutInBaseUnits == units)
    }

    @Test("A fraction of a base unit is rounded to the nearest unit", arguments: Self.roundingArguments)
    func roundsSubUnitFractions(amount: String, units: UInt64) throws {
        let terms = try CollectiblesBuybackTerms(nftAddress: "nft-1", offer: Self.offer(amount))

        #expect(terms.minimumPayoutInBaseUnits == units)
    }

    @Test("A price without a positive value or beyond the chain's range is refused", arguments: [
        "0",
        "-12.75",
        "18446744073709.551616",
    ])
    func refusesOutOfRangePrice(amount: String) {
        #expect(throws: CollectiblesBuybackSaleError.failed) {
            try CollectiblesBuybackTerms(nftAddress: "nft-1", offer: Self.offer(amount))
        }
    }
}

// MARK: - Helpers

private extension CollectiblesBuybackTermsOfferTests {
    static let priceArguments: [(amount: String, units: UInt64)] = [
        (amount: "12.75", units: 12_750_000),
        (amount: "15.3", units: 15_300_000),
        (amount: "0.01", units: 10_000),
        (amount: "280000", units: 280_000_000_000),
    ]

    static let roundingArguments: [(amount: String, units: UInt64)] = [
        (amount: "1.0000004", units: 1_000_000),
        (amount: "1.0000005", units: 1_000_001),
    ]

    static func offer(_ amount: String) -> CollectiblesBuybackOffer {
        CollectiblesBuybackOffer(amount: Decimal(string: amount)!, expiresAt: nil)
    }
}
