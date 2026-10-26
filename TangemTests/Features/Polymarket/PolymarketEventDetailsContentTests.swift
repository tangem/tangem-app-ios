//
//  PolymarketEventDetailsContentTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket event details mapping")
struct PolymarketEventDetailsContentTests {
    @Test("A 24h change of a thousand percent and more is abbreviated like the total volume")
    func hugeVolumeChangeIsAbbreviated() {
        let content = PolymarketEventDetailsContent.make(
            event: Self.makeEvent(markets: [], volume: 1_000_000, volume24h: 999_990),
            category: nil,
            abbreviatesHugeVolumeChange: true,
            onSelectOutcome: { _, _ in }
        )

        #expect(content.volumeChange.text.hasSuffix("M" + PercentFormatter.Suffix.default.value))
        #expect(content.volumeChange.text.count < 10)
    }

    @Test("Without phase two a huge 24h change keeps the regular percent format")
    func hugeVolumeChangeStaysRegularWithoutPhaseTwo() {
        let content = PolymarketEventDetailsContent.make(
            event: Self.makeEvent(markets: [], volume: 1_000_000, volume24h: 999_990),
            category: nil,
            onSelectOutcome: { _, _ in }
        )

        #expect(content.volumeChange.text == PercentFormatter().format(99999, option: .priceChange))
    }

    @Test("A 24h change below a thousand percent keeps the regular percent format")
    func regularVolumeChangeIsNotAbbreviated() {
        let content = PolymarketEventDetailsContent.make(
            event: Self.makeEvent(markets: [], volume: 300, volume24h: 100),
            category: nil,
            abbreviatesHugeVolumeChange: true,
            onSelectOutcome: { _, _ in }
        )

        #expect(content.volumeChange.text == PercentFormatter().format(0.5, option: .priceChange))
    }

    @Test("Markets follow the order the backend gave them")
    func explicitOrderIsFollowed() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "c", orderIndex: 2),
            Self.makeMarket(id: "a", orderIndex: 0),
            Self.makeMarket(id: "b", orderIndex: 1),
        ])

        #expect(content.activeMarkets.map(\.id) == ["a", "b", "c"])
    }

    @Test("An event that carries no order keeps the order it arrived in")
    func missingOrderKeepsArrival() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "first", orderIndex: nil),
            Self.makeMarket(id: "second", orderIndex: nil),
            Self.makeMarket(id: "third", orderIndex: nil),
        ])

        #expect(content.activeMarkets.map(\.id) == ["first", "second", "third"])
    }

    @Test("An order present on some markets never reshuffles the ones without it")
    func partialOrderKeepsArrival() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "a", orderIndex: 100),
            Self.makeMarket(id: "b", orderIndex: nil),
            Self.makeMarket(id: "c", orderIndex: nil),
        ])

        #expect(content.activeMarkets.map(\.id) == ["a", "b", "c"])
    }

    @Test("Closed markets are split out and their outcomes cannot be tapped")
    func closedMarketsAreSplitOut() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "open", status: .active),
            Self.makeMarket(id: "closed", status: .closed),
            Self.makeMarket(id: "archived", status: .archived),
        ])

        #expect(content.activeMarkets.map(\.id) == ["open"])
        #expect(content.closedMarkets.map(\.id) == ["closed"])
        #expect(content.closedMarkets.allSatisfy { $0.outcomes.isNotEmpty })
        #expect(content.closedMarkets.allSatisfy { $0.outcomes.allSatisfy { !$0.isEnabled } })
    }

    @Test("Archived markets are shown in neither the open nor the closed list")
    func archivedMarketsAreHidden() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "open", status: .active),
            Self.makeMarket(id: "archived", status: .archived),
            Self.makeMarket(id: "closed", status: .closed),
        ])

        #expect(content.activeMarkets.map(\.id) == ["open"])
        #expect(content.closedMarkets.map(\.id) == ["closed"])
        #expect(content.showsClosedMarketsToggle)
    }

    @Test("An event whose only finished markets are archived shows no closed section")
    func onlyArchivedFinishedMarketsHideClosedSection() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "open", status: .active),
            Self.makeMarket(id: "archived", status: .archived),
        ])

        #expect(content.activeMarkets.map(\.id) == ["open"])
        #expect(content.closedMarkets.isEmpty)
        #expect(!content.showsClosedMarketsToggle)
    }

    @Test("An event left with archived markets only shows them as closed instead of an empty list")
    func onlyArchivedMarketsAreShownAsClosed() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "first", status: .archived),
            Self.makeMarket(id: "second", status: .archived),
        ])

        #expect(content.activeMarkets.isEmpty)
        #expect(content.closedMarkets.map(\.id) == ["first", "second"])
        #expect(content.closedMarkets.allSatisfy { $0.outcomes.allSatisfy { !$0.isEnabled } })
    }

    @Test("An open market that stopped taking orders shows its outcomes disabled")
    func aMarketNotTakingOrdersDisablesItsOutcomes() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "taking", isAcceptingOrders: true),
            Self.makeMarket(id: "paused", isAcceptingOrders: false),
        ])

        #expect(content.activeMarkets.map(\.id) == ["taking", "paused"])
        #expect(content.activeMarkets.first { $0.id == "taking" }?.outcomes.allSatisfy(\.isEnabled) == true)
        #expect(content.activeMarkets.first { $0.id == "paused" }?.outcomes.contains { $0.isEnabled } == false)
        #expect(content.activeMarkets.first { $0.id == "paused" }?.outcomes.isNotEmpty == true)
    }

    @Test("Outcomes of a closed market show a dash instead of the price")
    func closedMarketOutcomesShowDash() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "open", status: .active),
            Self.makeMarket(id: "closed", status: .closed),
        ])

        let closedPrices = content.closedMarkets.flatMap(\.outcomes).map(\.priceText)
        let openPrices = content.activeMarkets.flatMap(\.outcomes).map(\.priceText)

        #expect(closedPrices.count == 2)
        #expect(closedPrices.allSatisfy { $0 == BalanceFormatter.defaultEmptyBalanceString })
        #expect(openPrices.count == 2)
        #expect(!openPrices.contains(BalanceFormatter.defaultEmptyBalanceString))
    }

    @Test("Outcomes of a market that stopped taking orders show a dash instead of the price")
    func pausedMarketOutcomesShowDash() {
        let content = Self.makeContent(markets: [
            Self.makeMarket(id: "taking", isAcceptingOrders: true),
            Self.makeMarket(id: "paused", isAcceptingOrders: false),
        ])

        let takingPrices = content.activeMarkets.first { $0.id == "taking" }?.outcomes.map(\.priceText) ?? []
        let pausedPrices = content.activeMarkets.first { $0.id == "paused" }?.outcomes.map(\.priceText)

        #expect(takingPrices.count == 2)
        #expect(!takingPrices.contains(BalanceFormatter.defaultEmptyBalanceString))
        #expect(pausedPrices == [BalanceFormatter.defaultEmptyBalanceString, BalanceFormatter.defaultEmptyBalanceString])
    }
}

// MARK: - Fixtures

private extension PolymarketEventDetailsContentTests {
    static func makeContent(markets: [PolymarketMarket]) -> PolymarketEventDetailsContent {
        .make(event: makeEvent(markets: markets), category: nil, onSelectOutcome: { _, _ in })
    }

    static func makeMarket(
        id: String,
        status: PolymarketEventStatus = .active,
        isAcceptingOrders: Bool = true,
        orderIndex: Int? = nil
    ) -> PolymarketMarket {
        PolymarketMarket(
            id: id,
            conditionId: nil,
            title: id,
            groupItemTitle: nil,
            imageURL: nil,
            iconURL: nil,
            status: status,
            isNegRisk: false,
            isAcceptingOrders: isAcceptingOrders,
            startDate: nil,
            endDate: nil,
            volume: nil,
            volume24h: nil,
            liquidity: nil,
            orderIndex: orderIndex,
            outcomes: [
                PolymarketOutcome(assetId: "\(id)-yes", title: "Yes", probability: 0.6),
                PolymarketOutcome(assetId: "\(id)-no", title: "No", probability: 0.4),
            ]
        )
    }

    static func makeEvent(markets: [PolymarketMarket], volume: Decimal? = nil, volume24h: Decimal? = nil) -> PolymarketEvent {
        PolymarketEvent(
            id: "event",
            slug: "event",
            title: "Title",
            description: nil,
            rulesURL: nil,
            imageURL: nil,
            iconURL: nil,
            status: .active,
            isLive: false,
            startDate: nil,
            endDate: nil,
            volume: volume,
            volume24h: volume24h,
            liquidity: nil,
            totalMarketsCount: markets.count,
            isNegRisk: false,
            displayMode: .plainMarkets,
            markets: markets
        )
    }
}
