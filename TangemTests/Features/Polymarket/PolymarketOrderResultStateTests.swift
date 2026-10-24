//
//  PolymarketOrderResultStateTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket order fill")
struct PolymarketOrderResultStateTests {
    @Test("A buy that took exactly what was quoted is fully placed")
    func buyOfTheQuotedSizeIsPlaced() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 100, takingAmount: 138),
            quotedShares: 138,
            side: .buy
        )

        #expect(state == .placed)
    }

    @Test("A buy filled at a better price takes more tokens than quoted and is still fully placed")
    func buyOverTheQuotedSizeIsPlaced() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 100, takingAmount: 140),
            quotedShares: 138,
            side: .buy
        )

        #expect(state == .placed)
    }

    @Test("A buy that took fewer tokens than quoted is partial")
    func buyUnderTheQuotedSizeIsPartial() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 100, takingAmount: 137),
            quotedShares: 138,
            side: .buy
        )

        #expect(state == .partiallyPlaced)
    }

    @Test("A sale is measured by the leg that carries the shares")
    func sellOfTheWholeSizeIsPlaced() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 1000, takingAmount: 720),
            quotedShares: 1000,
            side: .sell
        )

        #expect(state == .placed)
    }

    @Test("A sale that moved fewer shares than quoted is partial")
    func sellUnderTheQuotedSizeIsPartial() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 900, takingAmount: 650),
            quotedShares: 1000,
            side: .sell
        )

        #expect(state == .partiallyPlaced)
    }

    @Test("An order the exchange has not matched is still being processed")
    func unmatchedOrderIsStillProcessing() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(status: .delayed, makingAmount: 100, takingAmount: 138),
            quotedShares: 138,
            side: .buy
        )

        #expect(state == .stillProcessing)
    }

    @Test("A matched order that moved nothing is still being processed")
    func matchedOrderWithoutAnswerIsStillProcessing() {
        let state = PolymarketOrderResultViewModel.State(
            placement: .stub(makingAmount: 100, takingAmount: 0),
            quotedShares: 138,
            side: .buy
        )

        #expect(state == .stillProcessing)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderPlacement {
    static func stub(
        status: PolymarketOrderPlacementStatus = .matched,
        makingAmount: Decimal?,
        takingAmount: Decimal?
    ) -> Self {
        Self(
            orderId: "order",
            status: status,
            makingAmount: makingAmount,
            takingAmount: takingAmount,
            transactionHashes: []
        )
    }
}
