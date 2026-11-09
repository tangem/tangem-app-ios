//
//  PolymarketRedeemViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
import TangemPolymarket
import TangemUI
@testable import Tangem

@MainActor
@Suite("Polymarket claim screen")
struct PolymarketRedeemViewModelTests {
    @Test("A lost position explains above the button that closing pays nothing out")
    func lostExplainsClosing() {
        let sut = Self.makeSUT(position: .stub(cashPnl: -4, realizedPnl: -1, isRedeemable: true, settlement: .lost))

        #expect(sut.footerCaption == Localization.predictionPositionResultCloseNote)
    }

    @Test("A lost position titles the cash PnL of the shares it holds, leaving out earlier partial sales", arguments: [Decimal(0), -1, 3])
    func lostTitlesTheCashPnl(realizedPnl: Decimal) {
        let sut = Self.makeSUT(position: .stub(cashPnl: -4, realizedPnl: realizedPnl, isRedeemable: true, settlement: .lost))

        #expect(sut.title == Localization.predictionPositionResultLossTitle(PolymarketOrderFormatter.money(4)))
    }

    @Test("A lost position with nothing left to close has no caption")
    func lostWithoutCloseHasNoCaption() {
        let sut = Self.makeSUT(position: .stub(cashPnl: -4, isRedeemable: false, settlement: .lost))

        #expect(sut.footerCaption == nil)
    }

    @Test("A paying position keeps its payout caption", arguments: [PolymarketPositionSettlement.won, .split])
    func payingKeepsItsCaption(settlement: PolymarketPositionSettlement) {
        let sut = Self.makeSUT(position: .stub(isRedeemable: true, settlement: settlement))

        #expect(sut.footerCaption == Localization.predictionPositionResultBalanceNote)
    }
}

// MARK: - Helpers

private extension PolymarketRedeemViewModelTests {
    static func makeSUT(position: PolymarketPosition) -> PolymarketRedeemViewModel {
        PolymarketRedeemViewModel(
            position: position,
            redeemService: RedeemingStub(),
            signingButtonType: .holdToConfirm,
            onClaimed: { _ in },
            coordinator: RedeemRoutableStub()
        )
    }
}

// MARK: - Doubles

private struct RedeemingStub: PolymarketRedeeming {
    struct StubError: Error {}

    func claim(position: PolymarketPosition) async throws -> PolymarketRedeemRecord {
        throw StubError()
    }
}

private final class RedeemRoutableStub: PolymarketRedeemRoutable {
    func closeRedeem() {}
}
