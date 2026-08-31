//
//  PortfolioReviewSegmentPaletteTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("PortfolioReviewSegmentPalette")
struct PortfolioReviewSegmentPaletteTests {
    typealias SUT = PortfolioReviewSegmentPalette
    typealias Availability = PortfolioReviewAggregator.Availability

    // MARK: - Palette

    @Test("Nothing ranked, nothing coloured")
    func emptyRankingGetsNoColours() {
        #expect(SUT.colors(forRanked: []).isEmpty)
    }

    @Test("Ranks past the palette get no colour")
    func ranksPastThePaletteGetNothing() {
        let ids = (0 ..< 8).map { "asset\($0)" }

        let colors = SUT.colors(forRanked: ids)

        #expect(colors.count == Self.topAssetCount)
        #expect(Set(colors.keys) == Set(ids.prefix(Self.topAssetCount)))
    }

    @Test("The colour follows the rank, not the asset")
    func colourFollowsTheRank() throws {
        let first = try #require(SUT.colors(forRanked: ["btc", "eth"])["btc"])
        let second = try #require(SUT.colors(forRanked: ["eth", "btc"])["eth"])

        // Whoever ranks first wears the same colour, so a reshuffled portfolio recolours in place.
        #expect(first == second)
    }

    // MARK: - Segments

    @Test("Segments keep the order they arrive in, each carrying its own asset's colour")
    func segmentsKeepInputOrderAndColour() {
        let assets = [
            SummaryGaugeAsset(id: "small", name: "Small", fiatValue: 100, segmentColor: .red),
            SummaryGaugeAsset(id: "big", name: "Big", fiatValue: 300, segmentColor: .green),
            SummaryGaugeAsset(id: "uncharted", name: "Uncharted", fiatValue: 200, segmentColor: nil),
        ]
        let expectedColours: [Color] = [.red, .green]

        let segments = SummaryGaugeChart.segments(for: assets)

        // Deliberately out of balance order: ranking belongs upstream, and re-sorting here would flip these two.
        #expect(segments.map(\.id) == ["small", "big"])
        #expect(segments.map(\.color) == expectedColours)
        #expect(segments.map(\.value) == [100, 300])
    }

    // MARK: - Rows and arcs

    @Test("Every arc belongs to the row wearing the matching dot")
    func arcsAndDotsShareTheirAsset() {
        let review = makeReview(fiatAmounts: [400, 300, 200, 100])

        #expect(review.segments.map(\.id) == review.rows.rankedRowIDs)
    }

    @Test("A row's dot is the very colour its own arc is drawn with")
    func rowDotMatchesItsArc() throws {
        let content = try mapContent(fiatBalances: [400, 300, 200, 100])
        let arcsByID = try Dictionary(uniqueKeysWithValues: segments(of: content).map { ($0.id, $0.color) })

        let dots = content.tokenList.map(\.assetRow.indicatorColor)
        let arcs = content.tokenList.map { arcsByID[$0.id] }

        #expect(dots.allSatisfy { $0 != nil })
        #expect(dots == arcs)
    }

    @Test("Ranking follows the balances, not the order the holdings arrive in")
    func rankingFollowsBalancesNotInput() {
        let review = makeReview(fiatAmounts: [100, 200, 300, 400])

        // Fed ascending, so a colour handed out by arrival order would read asset0…asset3.
        #expect(review.rows.rankedRowIDs == ["asset3", "asset2", "asset1", "asset0"])
        #expect(review.segments.map(\.id) == review.rows.rankedRowIDs)
    }

    @Test("Equal balances leave the rows and the arcs in one order")
    func equalBalancesKeepOneOrder() {
        let review = makeReview(fiatAmounts: [100, 100, 100, 100])

        // A tie must not reshuffle the list: the ranking is stable, so the holdings keep the order they arrived in.
        #expect(review.rows.rankedRowIDs == ["asset0", "asset1", "asset2", "asset3"])
        #expect(review.segments.map(\.id) == review.rows.rankedRowIDs)
    }

    @Test("Assets past the top four are charted by neither an arc nor a dot")
    func assetsPastTheTopFourAreNotCharted() {
        let review = makeReview(fiatAmounts: [600, 500, 400, 300, 200, 100])

        #expect(review.segments.map(\.id) == ["asset0", "asset1", "asset2", "asset3"])
        #expect(!review.rows.map(\.id).contains("asset4"))
        #expect(!review.rows.map(\.id).contains("asset5"))
    }

    // MARK: - Through the mapper

    @Test("The mapper hands the rows and the donut one and the same ranking")
    func mapperWiresRowsAndDonutToOneRanking() throws {
        let content = try mapContent(fiatBalances: [500, 400, 300, 200, 100])
        let assets = try chartAssets(of: content)
        let segments = SummaryGaugeChart.segments(for: assets)

        #expect(segments.count == Self.topAssetCount)
        #expect(segments.map(\.id) == content.tokenList.rankedRowIDs)
        // Amounts rather than currency ids: pins the ranking to the balances without guessing at ids.
        #expect(segments.map(\.value) == [500, 400, 300, 200])
        // Four ranked rows plus the "Other" bucket, while every group still reaches the gauge for the centre total.
        #expect(content.tokenList.count == 5)
        #expect(assets.count == 5)
    }

    @Test("A donut that can't be drawn leaves every row without a dot")
    func unchartedDonutLeavesRowsWithoutDots() throws {
        // One failed balance is enough to fail the total, and a partial sum isn't charted.
        let content = try mapContent(fiatBalances: [500, 400, 300, 200, 100], totalBalance: .failed(cached: nil, failedItems: []))

        #expect(content.chart == .noData(.cantLoad))
        // Includes the "Other" bucket: its neutral marker reads as one of the dots, so it goes too.
        #expect(content.tokenList.count == 5)
        #expect(content.tokenList.allSatisfy { $0.assetRow.indicatorColor == nil })
    }

    // MARK: - Rows without a slice

    @Test("The Other bucket wears the neutral marker, not a rank colour")
    func otherBucketWearsTheNeutralMarker() throws {
        let content = try mapContent(fiatBalances: [500, 400, 300, 200, 100])

        let otherRow = try #require(content.tokenList.last)
        let rankColours = content.tokenList.dropLast().map(\.assetRow.indicatorColor)

        #expect(otherRow.assetRow.indicatorColor == SUT.otherIndicatorColor)
        #expect(!rankColours.contains(SUT.otherIndicatorColor))
        // It closes the list without an arc of its own — the donut charts assets, not the bucket.
        #expect(try !segments(of: content).map(\.id).contains(otherRow.id))
    }

    @Test("An addressless asset is listed without a dot")
    func addresslessAssetHasNoDot() throws {
        let review = makeReview([
            makeHolding(groupKey: "funded", amountInFiat: 100),
            makeHolding(groupKey: "addressless", availability: .noAddress, amountInFiat: nil),
        ])

        let addresslessRow = try #require(review.rows.first { $0.id == "addressless" })

        #expect(review.rows.rankedRowIDs == ["funded"])
        #expect(addresslessRow.assetRow.indicatorColor == nil)
    }

    @Test("Per-network child rows never carry a dot")
    func networkRowsCarryNoDot() throws {
        let review = makeReview([
            makeHolding(groupKey: "multi", networkKey: "ethereum", amountInFiat: 100),
            makeHolding(groupKey: "multi", networkKey: "tron", amountInFiat: 50),
        ])

        let item = try #require(review.rows.first)

        #expect(item.assetRow.indicatorColor != nil)
        #expect(item.networkRows.count == 2)
        #expect(item.networkRows.allSatisfy { $0.indicatorColor == nil })
    }

    @Test("A wallet holding nothing but zeroes draws no donut and still lists its tokens")
    func emptyStateLeavesRowsWithoutDots() throws {
        let content = try mapContent(fiatBalances: [0, 0, 0])

        #expect(content.chart == .noData(.noAmount))
        #expect(content.showsAddFunds)
        #expect(content.tokenList.count == 3)
        #expect(content.tokenList.allSatisfy { $0.assetRow.indicatorColor == nil })
    }

    // MARK: - Holdings without a value

    @Test("The mapper keeps an unpriced holding out of the ranking")
    func mapperLeavesUnpricedHoldingUncoloured() throws {
        let content = try content(of: mapPricedAndUnpriced())
        let assets = try chartAssets(of: content)

        // Two rows, but only the priced one is ranked — so a dot on the other would point at an arc nobody draws.
        #expect(content.tokenList.count == 2)
        #expect(content.tokenList.filter { $0.assetRow.indicatorColor != nil }.count == 1)
        #expect(assets.filter { $0.segmentColor != nil }.count == 1)
    }

    @Test("An unpriced holding is listed, but without a dot or an arc")
    func unpricedHoldingIsNotCharted() throws {
        let review = makeReview([
            makeHolding(groupKey: "funded", amountInFiat: 400),
            makeHolding(groupKey: "unpriced", availability: .noRate, amountInFiat: nil),
        ])

        let unpricedRow = try #require(review.rows.first { $0.id == "unpriced" })

        // Its arc would be zero-width and never drawn, so a dot on the row would point at nothing.
        #expect(review.rows.rankedRowIDs == ["funded"])
        #expect(unpricedRow.assetRow.indicatorColor == nil)
        #expect(!review.segments.map(\.id).contains("unpriced"))
    }
}

// MARK: - State unwrapping

private extension PortfolioReviewSegmentPaletteTests {
    func content(of state: PortfolioReviewViewModel.ViewState) throws -> PortfolioReviewViewModel.ViewState.Content {
        guard case .content(let content) = state else {
            throw TestError.notContent
        }

        return content
    }

    func chartAssets(of content: PortfolioReviewViewModel.ViewState.Content) throws -> [SummaryGaugeAsset] {
        guard case .loaded(let assets, _, _) = content.chart else {
            throw TestError.chartNotLoaded(content.chart)
        }

        return assets
    }

    func segments(of content: PortfolioReviewViewModel.ViewState.Content) throws -> [GaugeSegment] {
        SummaryGaugeChart.segments(for: try chartAssets(of: content))
    }

    enum TestError: Error {
        case notContent
        case chartNotLoaded(PortfolioReviewViewModel.ViewState.Chart)
    }
}

// MARK: - Fixtures

private extension PortfolioReviewSegmentPaletteTests {
    /// Pinned on purpose: growing the product rule or the palette is meant to break these tests.
    static let topAssetCount = 4

    /// One blockchain per wallet model, so every holding lands in an asset group of its own.
    static let blockchains: [Blockchain] = [
        .bitcoin(testnet: false),
        .ethereum(testnet: false),
        .cosmos(testnet: false),
        .solana(curve: .ed25519, testnet: false),
        .alephium(testnet: false),
    ]

    /// What one pass of the mapper produces: the rows and the donut's segments, both from one ranking.
    struct Review {
        let rows: [ForYouTokenListItem]
        let segments: [GaugeSegment]
    }

    /// Runs the real mapper over one wallet model per balance, each holding its own blockchain.
    func mapContent(
        fiatBalances: [Decimal],
        totalBalance: TotalBalanceState? = nil
    ) throws -> PortfolioReviewViewModel.ViewState.Content {
        try content(of: map(fiatBalances: fiatBalances, totalBalance: totalBalance))
    }

    func map(fiatBalances: [Decimal], totalBalance: TotalBalanceState? = nil) -> PortfolioReviewViewModel.ViewState {
        let tokenItems = fiatBalances.indices.map { index in
            TokenItemType.default(
                WalletModelTestsMock(
                    tokenItem: .blockchain(.init(Self.blockchains[index], derivationPath: nil)),
                    isEmpty: false,
                    fiatBalance: fiatBalances[index]
                )
            )
        }

        return PortfolioReviewMapper().map(
            tokenItems: tokenItems,
            totalBalance: totalBalance ?? .loaded(balance: fiatBalances.reduce(0, +)),
            indicators: [:],
            timeframe: .day
        ).state
    }

    /// Runs the real mapper over one priced asset and one held with no rate at all.
    func mapPricedAndUnpriced() -> PortfolioReviewViewModel.ViewState {
        let priced = WalletModelTestsMock(
            tokenItem: .blockchain(.init(Self.blockchains[0], derivationPath: nil)),
            isEmpty: false,
            fiatBalance: 400
        )
        let unpriced = WalletModelTestsMock(
            tokenItem: .blockchain(.init(Self.blockchains[1], derivationPath: nil)),
            isEmpty: false,
            fiatBalanceProvider: MutableTokenBalanceProviderMock(initialState: .empty(.custom))
        )

        return PortfolioReviewMapper().map(
            tokenItems: [.default(priced), .default(unpriced)],
            totalBalance: .loaded(balance: 400),
            indicators: [:],
            timeframe: .day
        ).state
    }

    /// One unrelated asset per amount, named after its position in the input.
    func makeReview(fiatAmounts: [Decimal]) -> Review {
        makeReview(fiatAmounts.enumerated().map { makeHolding(groupKey: "asset\($0.offset)", amountInFiat: $0.element) })
    }

    func makeReview(_ holdings: [PortfolioReviewAggregator.TokenHolding]) -> Review {
        let (topHoldings, other, addressless) = PortfolioReviewAggregator.aggregate(holdings)
        let colors = SUT.colors(forRanked: topHoldings.chartableKeys)

        let rows = PortfolioRowBuilder().build(
            topHoldings: topHoldings,
            other: other,
            addressless: addressless,
            colors: colors,
            indicators: [:],
            timeframe: .day
        )
        let assets = (topHoldings + other).map {
            SummaryGaugeAsset(id: $0.key, name: $0.tokenItem.name, fiatValue: $0.amountInFiat, segmentColor: colors[$0.key])
        }

        return Review(rows: rows, segments: SummaryGaugeChart.segments(for: assets))
    }

    func makeHolding(
        groupKey: String,
        networkKey: String = "ethereum",
        availability: Availability = .content,
        amountInFiat: Decimal?
    ) -> PortfolioReviewAggregator.TokenHolding {
        PortfolioReviewAggregator.TokenHolding(
            groupKey: groupKey,
            networkKey: networkKey,
            networkName: networkKey,
            symbol: groupKey.uppercased(),
            tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
            isCustom: false,
            amountInCrypto: 1,
            amountInFiat: amountInFiat,
            availability: availability
        )
    }
}

// MARK: - Row list

private extension Array where Element == ForYouTokenListItem {
    /// Ids of the rows wearing a rank colour. The "Other" bucket has no token behind it and carries the neutral marker.
    var rankedRowIDs: [String] {
        filter { $0.assetRow.tokenItem != nil && $0.assetRow.indicatorColor != nil }.map(\.id)
    }
}
