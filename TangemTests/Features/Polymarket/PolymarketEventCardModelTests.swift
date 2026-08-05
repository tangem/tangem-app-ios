//
//  PolymarketEventCardModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import XCTest
import TangemPolymarket
@testable import Tangem

final class PolymarketEventCardModelTests: XCTestCase {
    // MARK: - Affirmative outcome

    func testAffirmativeOutcomeResolvedByLabelNotByOrder() {
        // Backend order is not guaranteed: "No" comes first, "Yes" second.
        let market = makeMarket(outcomes: [
            makeOutcome(id: "no", title: "No", probability: 0.36),
            makeOutcome(id: "yes", title: "Yes", probability: 0.64),
        ])
        let event = makeEvent(totalMarketsCount: 1, markets: [market])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        let subtitle = model.rows.first?.subtitle ?? ""
        XCTAssertTrue(subtitle.contains("64"), "Expected the affirmative (Yes) probability, got \(subtitle)")
        XCTAssertFalse(subtitle.contains("36"))

        let outcomes = model.rows.first?.outcomes
        XCTAssertEqual(outcomes?.first(where: { $0.title == "Yes" })?.style, .affirmative)
        XCTAssertEqual(outcomes?.first(where: { $0.title == "No" })?.style, .negative)
    }

    // MARK: - Row cap and chip

    func testRowsCappedAndChipCountedFromRenderedRows() {
        // A full six-market list must still render two rows and count the remainder into the chip.
        let markets = (0 ..< 6).map { makeMarket(id: "m\($0)", outcomes: [makeOutcome(id: "y\($0)", title: "Yes", probability: 0.5)]) }
        let event = makeEvent(totalMarketsCount: 6, markets: markets)

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.rows.count, 2)
        XCTAssertEqual(model.additionalOutcomesCount, 4)
    }

    func testPartialMarketListStaysMultiMarket() {
        // Only one of six markets loaded — still multi-market, chip counts the rest.
        let event = makeEvent(totalMarketsCount: 6, markets: [makeMarket(outcomes: [makeOutcome(id: "y", title: "Yes", probability: 0.5)])])

        let model = PolymarketEventCard.Model.make(event: event, category: nil, isInActivePredicts: false, onSelectOutcome: { _, _ in })

        XCTAssertEqual(model.variant, .multiMarket)
        XCTAssertEqual(model.rows.count, 1)
        XCTAssertEqual(model.additionalOutcomesCount, 5)
    }
}

// MARK: - Stubs

private extension PolymarketEventCardModelTests {
    func makeOutcome(id: String, title: String, probability: Decimal) -> PolymarketOutcome {
        PolymarketOutcome(assetId: id, title: title, probability: probability)
    }

    func makeMarket(id: String = "market", outcomes: [PolymarketOutcome]) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            title: id,
            groupItemTitle: id,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isNegRisk: false,
            startDate: nil,
            endDate: nil,
            volume: 1_000_000,
            volume24h: nil,
            liquidity: nil,
            outcomes: outcomes
        )
    }

    func makeEvent(totalMarketsCount: Int, markets: [PolymarketMarket]) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "slug",
            title: "Title",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            startDate: nil,
            endDate: nil,
            volume: 1_000_000,
            volume24h: nil,
            liquidity: nil,
            totalMarketsCount: totalMarketsCount,
            isNegRisk: false,
            displayMode: .groupedOutcomes,
            markets: markets
        )
    }
}
