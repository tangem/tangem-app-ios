//
//  PolymarketOrderResultClosingTests.swift
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

@MainActor
@Suite("Polymarket order result closing a position")
struct PolymarketOrderResultClosingTests {
    @Test("Selling every held share closes the position and keeps the sheet from swiping away")
    func fullSaleClosesThePosition() {
        let sut = makeSUT(side: .sell, held: 100, sold: 100)

        #expect(sut.closesPosition)
        #expect(sut.blocksSwipeDismiss)
    }

    @Test("A residue below the dust threshold still counts as closed")
    func dustResidueClosesThePosition() {
        let sut = makeSUT(side: .sell, held: 100, sold: Decimal(string: "99.995")!)

        #expect(sut.closesPosition)
    }

    @Test("A residue of exactly the dust threshold keeps the position open")
    func dustBoundaryKeepsThePosition() {
        let sut = makeSUT(side: .sell, held: 100, sold: Decimal(string: "99.99")!)

        #expect(!sut.closesPosition)
        #expect(!sut.blocksSwipeDismiss)
    }

    @Test("A partial sale keeps the position open")
    func partialSaleKeepsThePosition() {
        let sut = makeSUT(side: .sell, held: 100, sold: 40)

        #expect(!sut.closesPosition)
        #expect(!sut.blocksSwipeDismiss)
    }

    @Test("A sale that did not fill does not close the position")
    func unfilledSaleKeepsThePosition() {
        let sut = makeSUT(side: .sell, held: 100, sold: 100, state: .noFill)

        #expect(!sut.closesPosition)
    }

    @Test("A buy never closes a position")
    func buyNeverClosesThePosition() {
        let sut = makeSUT(side: .buy, held: 100, sold: 100)

        #expect(!sut.closesPosition)
    }
}

// MARK: - Helpers

private extension PolymarketOrderResultClosingTests {
    func makeSUT(
        side: PolymarketOrderSide,
        held: Decimal?,
        sold: Decimal,
        state: PolymarketOrderResultViewModel.State = .placed
    ) -> PolymarketOrderResultViewModel {
        PolymarketOrderResultViewModel(
            state: state,
            content: .init(
                market: PolymarketOrderMarketRow.Model(
                    question: "Will it happen?",
                    imageURL: nil,
                    outcomeTitle: "Yes",
                    outcomePriceText: "50¢",
                    outcomeStyle: .affirmative
                ),
                placedAt: Date(),
                orderedAmount: 50,
                filledAmount: 50,
                tokensBought: sold,
                resolutionDate: nil,
                side: side,
                heldShares: held
            ),
            coordinator: nil
        )
    }
}
