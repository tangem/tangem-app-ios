//
//  PolymarketPositionMoneyTests.swift
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

@Suite("Polymarket position money", .timeLimit(.minutes(1)))
struct PolymarketPositionMoneyTests {
    private typealias Money = PolymarketOrderFormatter

    @Test("A running position pays a dollar a share if it wins, and the profit is that payout less what was invested")
    func payoutAndProfit() throws {
        let model = Self.phaseTwo(Self.position(size: 250, initialValue: 100, currentValue: 120))
        let payout = try #require(model.payout)

        #expect(payout.valueText == Money.money(250))
        #expect(payout.profitText.hasPrefix("\(Money.signedMoney(150)) "))
    }

    @Test("A settled position promises no payout")
    func settledPositionHasNoPayout() {
        let model = Self.phaseTwo(Self.position(size: 250, initialValue: 100, currentValue: 250, settlement: .won))

        #expect(model.payout?.valueText == nil)
    }

    @Test("The profit tiles show the unrealized and realized results with their signs")
    func profitTilesKeepTheirSigns() {
        let model = PolymarketPositionDetailsView.Model.make(
            position: Self.position(cashPnl: -30, realizedPnl: 12.5),
            openEventDetails: {},
            onClosePosition: {},
            onBuy: {},
            onMarketUnavailable: {},
            onHint: { _ in },
            loadingSide: nil
        )
        let values = Dictionary(uniqueKeysWithValues: model.stats.map { ($0.id, $0.value) })

        #expect(values["unrealized"] == Money.signedMoney(-30))
        #expect(values["realized"] == Money.signedMoney(12.5))
    }

    @Test("The realized profit shows its signed amount, and a result under a cent is not shown")
    func realizedProfitKeepsItsSign() throws {
        let loss = try #require(Self.phaseTwo(Self.position(cashPnl: 40, realizedPnl: -7.25)).realizedProfit)

        #expect(loss.valueText == Money.signedMoney(-7.25))
        #expect(Self.phaseTwo(Self.position(cashPnl: 40, realizedPnl: Decimal(4) / 1000)).realizedProfit?.valueText == nil)
    }
}

// MARK: - Fixtures

private extension PolymarketPositionMoneyTests {
    static func phaseTwo(_ position: PolymarketPosition) -> PolymarketPositionDetailsPhaseTwoView.Model {
        PolymarketPositionDetailsPhaseTwoView.Model.make(
            position: position,
            openEventDetails: {},
            onClosePosition: {},
            onBuy: {},
            onMarketUnavailable: {},
            onHint: { _ in },
            loadingSide: nil
        )
    }

    static func position(
        size: Decimal = 10,
        initialValue: Decimal = 5,
        currentValue: Decimal = 6,
        cashPnl: Decimal = 1,
        realizedPnl: Decimal = 0,
        settlement: PolymarketPositionSettlement? = nil
    ) -> PolymarketPosition {
        PolymarketPosition(
            conditionId: "0x1",
            assetId: "2",
            marketId: "3",
            version: .v1,
            eventId: "4",
            eventTitle: "Event",
            title: "Question",
            iconURL: nil,
            endDate: nil,
            outcome: "Yes",
            outcomeIndex: 0,
            size: size,
            avgPrice: 0.5,
            curPrice: 0.6,
            initialValue: initialValue,
            currentValue: currentValue,
            cashPnl: cashPnl,
            pnlRatio: 0.2,
            realizedPnl: realizedPnl,
            isRedeemable: false,
            isNegRisk: false,
            isAcceptingOrders: true,
            isLive: false,
            resolutionStatus: settlement == nil ? .open : .resolved,
            settlement: settlement
        )
    }
}
