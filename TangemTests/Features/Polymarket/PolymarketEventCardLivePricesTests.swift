//
//  PolymarketEventCardLivePricesTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemPolymarketUI
@testable import Tangem

@Suite("Polymarket event card live prices")
struct PolymarketEventCardLivePricesTests {
    private typealias Fixtures = PolymarketLiveQuotesFixtures

    // MARK: - Outcome button

    @Test("Without a live quote the button shows the price from the backend")
    func buttonWithoutQuoteShowsBackendPrice() {
        let card = makeCard(quotes: [])

        #expect(buttonTexts(card) == [cents("0.42"), cents("0.58")])
    }

    @Test("With a live quote the button shows the best ask, an empty ask shows a dash")
    func buttonWithQuoteShowsTheBestAsk() {
        let card = makeCard(quotes: [
            Fixtures.quote("a-m0-yes", bid: "0.36", ask: "0.37", lastTrade: "0.5"),
            Fixtures.quote("a-m0-no", bid: "0.62", lastTrade: "0.5"),
        ])

        #expect(buttonTexts(card) == [cents("0.37"), BalanceFormatter.defaultEmptyBalanceString])
    }

    // MARK: - Grouped row

    @Test("A grouped row shows the midpoint of the Yes bid and ask while they are at most 0.1 apart")
    func groupedRowShowsTheMidpointOfANarrowSpread() {
        let card = makeGroupedCard(quote: Fixtures.quote("a-m0-yes", bid: "0.7", ask: "0.8", lastTrade: "0.66"))

        #expect(card.rows.first?.subtitle == percent("0.75"))
    }

    @Test("A grouped row shows the last trade when the spread is wider than 0.1")
    func groupedRowShowsTheLastTradeOfAWideSpread() {
        let card = makeGroupedCard(quote: Fixtures.quote("a-m0-yes", bid: "0.6", ask: "0.8", lastTrade: "0.66"))

        #expect(card.rows.first?.subtitle == percent("0.66"))
    }

    @Test("A grouped row shows the last trade when a side of the book is empty")
    func groupedRowShowsTheLastTradeOfAnEmptySide() {
        let card = makeGroupedCard(quote: Fixtures.quote("a-m0-yes", bid: "0.7", lastTrade: "0.66"))

        #expect(card.rows.first?.subtitle == percent("0.66"))
    }

    @Test("A grouped row falls back to the backend when the spread is wide and there was no trade yet")
    func groupedRowFallsBackToBackendWithoutATrade() {
        let card = makeGroupedCard(quote: Fixtures.quote("a-m0-yes", bid: "0.6", ask: "0.8"))

        #expect(card.rows.first?.subtitle == percent("0.42"))
    }

    @Test("A grouped row reads only the quote of the Yes outcome")
    func groupedRowIgnoresTheNoQuote() {
        let card = makeGroupedCard(quote: Fixtures.quote("a-m0-no", bid: "0.2", ask: "0.25", lastTrade: "0.22"))

        #expect(card.rows.first?.subtitle == percent("0.42"))
    }
}

// MARK: - Helpers

private extension PolymarketEventCardLivePricesTests {
    func makeCard(quotes: [PolymarketOutcomeQuote]) -> PolymarketEventCard.Model {
        PolymarketEventCard.Model.make(
            event: Fixtures.event(id: "a"),
            category: nil,
            isInActivePredicts: false,
            liveQuotesByAssetId: Dictionary(uniqueKeysWithValues: quotes.map { ($0.assetId, $0) }),
            onSelectOutcome: { _, _ in }
        )
    }

    func makeGroupedCard(quote: PolymarketOutcomeQuote) -> PolymarketEventCard.Model {
        PolymarketEventCard.Model.make(
            event: Fixtures.event(id: "a", groupItemTitle: "Harry Kane"),
            category: nil,
            isInActivePredicts: false,
            liveQuotesByAssetId: [quote.assetId: quote],
            onSelectOutcome: { _, _ in }
        )
    }

    func buttonTexts(_ card: PolymarketEventCard.Model) -> [String?] {
        card.rows.first?.outcomes.map(\.priceText) ?? []
    }

    func cents(_ probability: String) -> String {
        PolymarketPriceFormatter.centsText(Decimal(string: probability))
    }

    func percent(_ probability: String) -> String {
        PolymarketPriceFormatter.percentText(Decimal(string: probability))
    }
}
