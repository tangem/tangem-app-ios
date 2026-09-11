//
//  TokenQuoteInheritingPriceUsdTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("TokenQuote.inheritingPriceUsd")
struct TokenQuoteInheritingPriceUsdTests {
    private static let currencyId = "usd-coin"

    @Test("A Markets quote without a USD price keeps the stored USD price and takes everything else from itself")
    func unpricedQuoteInheritsStoredPriceUsd() {
        let stored = makeQuote(price: 1, priceUsd: 1, priceChange24h: 0.1, currencyCode: "USD", date: .distantPast)
        let incoming = makeQuote(price: 85.43, priceUsd: nil, priceChange24h: -1.5, currencyCode: "RUB", date: .now)

        let merged = incoming.inheritingPriceUsd(from: stored)

        #expect(merged.priceUsd == 1)
        #expect(merged.price == incoming.price)
        #expect(merged.priceChange24h == incoming.priceChange24h)
        #expect(merged.currencyCode == incoming.currencyCode)
        #expect(merged.date == incoming.date)
    }

    @Test("A quote that carries its own USD price is saved as is")
    func pricedQuoteKeepsItsOwnPriceUsd() {
        let stored = makeQuote(price: 1, priceUsd: 1, priceChange24h: nil, currencyCode: "USD", date: .distantPast)
        let incoming = makeQuote(price: 0.99, priceUsd: 0.99, priceChange24h: nil, currencyCode: "USD", date: .now)

        #expect(incoming.inheritingPriceUsd(from: stored) == incoming)
    }

    @Test("Without a stored USD price there is nothing to inherit")
    func unpricedQuoteStaysUnpricedWithoutStoredPriceUsd() {
        let incoming = makeQuote(price: 85.43, priceUsd: nil, priceChange24h: nil, currencyCode: "RUB", date: .now)
        let storedWithoutUsd = makeQuote(price: 80, priceUsd: nil, priceChange24h: nil, currencyCode: "RUB", date: .distantPast)

        #expect(incoming.inheritingPriceUsd(from: nil) == incoming)
        #expect(incoming.inheritingPriceUsd(from: storedWithoutUsd) == incoming)
    }
}

// MARK: - Fixtures

private extension TokenQuoteInheritingPriceUsdTests {
    func makeQuote(price: Decimal, priceUsd: Decimal?, priceChange24h: Decimal?, currencyCode: String, date: Date) -> TokenQuote {
        TokenQuote(
            currencyId: Self.currencyId,
            price: price,
            priceUsd: priceUsd,
            priceChange24h: priceChange24h,
            priceChange7d: nil,
            priceChange30d: nil,
            currencyCode: currencyCode,
            date: date
        )
    }
}
