//
//  PolymarketPositionPresentationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemPolymarketUI
import TangemUI
@testable import Tangem

@Suite("Polymarket position presentation")
struct PolymarketPositionPresentationTests {
    // MARK: - Finished positions

    @Test("A finished row keeps its result badge with the amount")
    func finishedRowKeepsTheBadge() {
        let model = PolymarketPositionRow.Model.make(closedPosition: .stub(status: .won, realizedPnl: 4))

        guard case .status(let status) = model.trailing else {
            Issue.record("A finished row shows its result as a badge")
            return
        }

        #expect(status.appearance == .success)
        #expect(status.text.contains(PolymarketOrderFormatter.money(4)))
    }

    // MARK: - Settled card border

    @Test("A settled card is outlined by its result first, then by the sign of the open PnL", arguments: [
        GlowCase(settlement: .won, cashPnl: -5, realizedPnl: -10, expected: .info),
        GlowCase(settlement: .won, cashPnl: 5, realizedPnl: 0, expected: .info),
        GlowCase(settlement: .lost, cashPnl: 5, realizedPnl: 10, expected: .error),
        GlowCase(settlement: .lost, cashPnl: -5, realizedPnl: 0, expected: .error),
        GlowCase(settlement: .split, cashPnl: -1, realizedPnl: 10, expected: .error),
        GlowCase(settlement: .split, cashPnl: 1, realizedPnl: -10, expected: .info),
        GlowCase(settlement: .split, cashPnl: 0, realizedPnl: -10, expected: .info),
        GlowCase(settlement: .unknown, cashPnl: -1, realizedPnl: 0, expected: .error),
        GlowCase(settlement: .unknown, cashPnl: 1, realizedPnl: 0, expected: .info),
        GlowCase(settlement: nil, cashPnl: -1, realizedPnl: 0, expected: nil),
    ])
    func settledCardBorder(glowCase: GlowCase) {
        let position = PolymarketPosition.stub(
            cashPnl: glowCase.cashPnl,
            realizedPnl: glowCase.realizedPnl,
            settlement: glowCase.settlement
        )

        #expect(PolymarketPositionRow.Model.make(position: position).glowRing == glowCase.expected)
    }

    // MARK: - Details PnL tiles

    @Test("Unrealized and realized PnL are blue when up, red when down and plain at zero", arguments: [
        ToneCase(pnl: 3, expected: .gain),
        ToneCase(pnl: -3, expected: .loss),
        ToneCase(pnl: 0, expected: .neutral),
    ])
    func pnlTilesTone(toneCase: ToneCase) throws {
        let position = PolymarketPosition.stub(cashPnl: toneCase.pnl, realizedPnl: toneCase.pnl)
        let model = PolymarketPositionDetailsView.Model.make(
            position: position,
            openEventDetails: {},
            onClosePosition: {},
            onBuy: {},
            onMarketUnavailable: {},
            onHint: { _ in },
            loadingSide: nil
        )

        let unrealized = try #require(model.stats.first { $0.id == "unrealized" })
        let realized = try #require(model.stats.first { $0.id == "realized" })

        #expect(unrealized.tone == toneCase.expected)
        #expect(realized.tone == toneCase.expected)
    }

    // MARK: - Trading actions

    @Test("Buy and Cash out stay locked while a notice explains the resolution", arguments: [
        PolymarketResolutionStatus.pendingResolution,
        .proposed,
        .disputed,
    ])
    func actionsLockedBehindNotice(resolution: PolymarketResolutionStatus) throws {
        let taps = TapLog()
        let model = Self.detailsModel(position: .stub(resolutionStatus: resolution, isAcceptingOrders: false), taps: taps)

        #expect(model.notice != nil)
        #expect(try #require(model.primaryAction).isEnabled == false)
        #expect(try #require(model.secondaryAction).isEnabled == false)
    }

    @Test("Without a notice, a market out of trading answers both buttons with the unavailable sheet", arguments: [
        UnavailableCase(resolution: .resolved, settlement: .won),
        UnavailableCase(resolution: .unknown, settlement: nil),
    ])
    func actionsExplainUnavailableMarket(unavailableCase: UnavailableCase) throws {
        let taps = TapLog()
        let position = PolymarketPosition.stub(
            settlement: unavailableCase.settlement,
            resolutionStatus: unavailableCase.resolution,
            isAcceptingOrders: false
        )
        let model = Self.detailsModel(position: position, taps: taps)
        let primary = try #require(model.primaryAction)
        let secondary = try #require(model.secondaryAction)

        #expect(model.notice == nil)
        #expect(primary.isEnabled)
        #expect(secondary.isEnabled)

        primary.perform()
        secondary.perform()

        #expect(taps.marketUnavailable == 2)
        #expect(taps.buy == 0)
        #expect(taps.cashOut == 0)
    }

    @Test("An open market taking orders goes straight to the order")
    func openMarketTrades() throws {
        let taps = TapLog()
        let model = Self.detailsModel(position: .stub(), taps: taps)
        let primary = try #require(model.primaryAction)
        let secondary = try #require(model.secondaryAction)

        #expect(primary.isEnabled)
        #expect(secondary.isEnabled)

        primary.perform()
        secondary.perform()

        #expect(taps.buy == 1)
        #expect(taps.cashOut == 1)
        #expect(taps.marketUnavailable == 0)
    }

    @Test("An open market that stopped taking orders keeps both buttons locked")
    func openMarketWithoutOrdersIsLocked() throws {
        let model = Self.detailsModel(position: .stub(isAcceptingOrders: false), taps: TapLog())

        #expect(model.notice == nil)
        #expect(try #require(model.primaryAction).isEnabled == false)
        #expect(try #require(model.secondaryAction).isEnabled == false)
    }
}

extension PolymarketPositionPresentationTests {
    struct GlowCase: Sendable, CustomTestStringConvertible {
        let settlement: PolymarketPositionSettlement?
        let cashPnl: Decimal
        let realizedPnl: Decimal
        let expected: GlowRingAppearance?

        var testDescription: String {
            "\(settlement?.rawValue ?? "open"), cash \(cashPnl), realized \(realizedPnl)"
        }
    }

    struct UnavailableCase: Sendable, CustomTestStringConvertible {
        let resolution: PolymarketResolutionStatus
        let settlement: PolymarketPositionSettlement?

        var testDescription: String { resolution.rawValue }
    }

    final class TapLog {
        var buy = 0
        var cashOut = 0
        var marketUnavailable = 0
    }

    static func detailsModel(position: PolymarketPosition, taps: TapLog) -> PolymarketPositionDetailsView.Model {
        PolymarketPositionDetailsView.Model.make(
            position: position,
            openEventDetails: {},
            onClosePosition: { taps.cashOut += 1 },
            onBuy: { taps.buy += 1 },
            onMarketUnavailable: { taps.marketUnavailable += 1 },
            onHint: { _ in },
            loadingSide: nil
        )
    }

    struct ToneCase: Sendable, CustomTestStringConvertible {
        let pnl: Decimal
        let expected: PolymarketValueTone

        var testDescription: String { "\(pnl)" }
    }
}
