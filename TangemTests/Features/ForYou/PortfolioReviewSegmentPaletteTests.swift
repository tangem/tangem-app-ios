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

    // MARK: - Slices

    @Test("Nothing ranked, nothing coloured")
    func emptyRankingGetsNoSlices() {
        #expect(SUT.slices(forRanked: []).isEmpty)
    }

    @Test("Ranks past the palette get no slice")
    func ranksPastThePaletteGetNothing() {
        let ids = (0 ..< 14).map { "asset\($0)" }

        let slices = SUT.slices(forRanked: ids)

        // Ten ranks is the product rule, so growing the palette is meant to break this on purpose.
        #expect(slices.count == 10)
        #expect(Set(slices.keys) == Set(ids.prefix(10)))
    }

    @Test("The slice follows the rank, not the asset")
    func sliceFollowsTheRank() throws {
        let first = try #require(SUT.slices(forRanked: ["btc", "eth"])["btc"])
        let second = try #require(SUT.slices(forRanked: ["eth", "btc"])["eth"])

        // Whoever ranks first wears the same pair, so a reshuffled portfolio recolours in place.
        #expect(first.arc == second.arc)
        #expect(first.indicator == second.indicator)
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

        #expect(review.segments.count == 4)
        #expect(review.segments.map(\.id) == review.rows.rankedRowIDs)
    }

    @Test("A row's dot is the indicator colour of its own rank")
    func rowDotIsItsRankIndicator() {
        let review = makeReview(fiatAmounts: [400, 300, 200, 100])

        let dots = review.rows.map(\.assetRow.indicatorColor)
        let expectedDots = review.rows.map { review.slices[$0.id]?.indicator }

        #expect(dots.allSatisfy { $0 != nil })
        // Discriminates the indicator half of the slice from the arc half, and a lookup by the wrong key.
        #expect(dots == expectedDots)
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
        #expect(review.segments.count == 4)
        #expect(review.segments.map(\.id) == review.rows.rankedRowIDs)
    }

    @Test("Assets past the top ten are charted by neither an arc nor a dot")
    func assetsPastTheTopTenAreNotCharted() {
        let review = makeReview(fiatAmounts: Self.twelveDescendingAmounts)

        // The two past the top get no arc of their own: they are inside the bucket that closes the ring.
        #expect(review.segments.map(\.id) == (0 ..< 10).map { "asset\($0)" } + [PortfolioRowBuilder.otherID])
        #expect(!review.rows.map(\.id).contains("asset10"))
        #expect(!review.rows.map(\.id).contains("asset11"))
    }

    // MARK: - Through the mapper

    @Test("The mapper hands the rows and the donut one and the same ranking")
    func mapperWiresRowsAndDonutToOneRanking() throws {
        let content = try content(of: map(fiatBalances: Self.twelveDescendingAmounts))
        let assets = try chartAssets(of: content)
        let segments = SummaryGaugeChart.segments(for: assets)

        // Ten ranked arcs plus the bucket that closes the ring.
        #expect(segments.count == 11)
        #expect(segments.dropLast().map(\.id) == content.tokenList.rankedRowIDs)
        // Amounts rather than currency ids: pins the ranking to the balances without guessing at ids.
        // The last one is the bucket, 200 + 100.
        #expect(segments.map(\.value) == [1200, 1100, 1000, 900, 800, 700, 600, 500, 400, 300, 300])
        #expect(content.tokenList.count == 11)
        // Collapsing the tail into one asset must not move the centre total.
        #expect(assets.map(\.fiatValue).reduce(0, +) == 7800)
    }

    @Test("A failed total does not unchart the donut: the holdings still rank and the rows keep their dots")
    func failedTotalKeepsDonutAndDots() throws {
        let state = map(fiatBalances: Self.twelveDescendingAmounts, totalBalance: .failed(cached: nil, failedItems: []))
        let content = try content(of: state)
        let assets = try chartAssets(of: content)

        // Ten ranked arcs plus the bucket, exactly as with a loaded total.
        #expect(assets.count == 11)
        #expect(content.tokenList.count == 11)
        #expect(content.tokenList.allSatisfy { $0.assetRow.indicatorColor != nil })
    }

    // MARK: - Rows without a slice

    @Test("The Other bucket wears the neutral marker, not a rank colour")
    func otherBucketWearsTheNeutralMarker() throws {
        let review = makeReview(fiatAmounts: Self.twelveDescendingAmounts)

        let otherRow = try #require(review.rows.last)
        let rankColours = review.slices.values.map(\.indicator)

        let otherSegment = try #require(review.segments.first { $0.id == otherRow.id })

        #expect(otherRow.assetRow.indicatorColor == SUT.otherIndicatorColor)
        #expect(!rankColours.contains(SUT.otherIndicatorColor))
        // Its arc closes the ring and answers taps, so it wears the ring's own grey rather than a rank shade.
        #expect(otherSegment.color == SUT.otherArcColor)
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

    @Test("The empty state draws no donut, so it leaves every row without a dot")
    func emptyStateLeavesRowsWithoutDots() {
        let holdings = (0 ..< 3).map { makeHolding(groupKey: "asset\($0)", amountInFiat: 0) }

        let rows = PortfolioRowBuilder().build(
            topHoldings: PortfolioReviewAggregator.aggregateEmpty(holdings),
            other: [],
            addressless: [],
            slices: [:],
            indicators: [:],
            timeframe: .day
        )

        #expect(rows.count == 3)
        #expect(rows.allSatisfy { $0.assetRow.indicatorColor == nil })
    }

    @Test("A wallet of zeroes reads as no amount and offers Add Funds")
    func zeroWalletReadsAsNoAmountAndOffersAddFunds() throws {
        let content = try content(of: map(fiatBalances: [0, 0, 0]))

        #expect(content.chart == .noData(.noAmount))
        #expect(content.showsAddFunds)
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

    enum TestError: Error {
        case notContent
        case chartNotLoaded(PortfolioReviewViewModel.ViewState.Chart)
    }
}

// MARK: - Fixtures

private extension PortfolioReviewSegmentPaletteTests {
    /// Twelve amounts: ten fill the ranking, the last two fall into the "Other" bucket.
    static let twelveDescendingAmounts: [Decimal] = [1200, 1100, 1000, 900, 800, 700, 600, 500, 400, 300, 200, 100]

    /// One blockchain per wallet model, so every holding lands in an asset group of its own.
    static let blockchains: [Blockchain] = [
        .bitcoin(testnet: false),
        .ethereum(testnet: false),
        .cosmos(testnet: false),
        .solana(curve: .ed25519, testnet: false),
        .alephium(testnet: false),
        .polygon(testnet: false),
        .avalanche(testnet: false),
        .tron(testnet: false),
        .litecoin,
        .dogecoin,
        .kaspa(testnet: false),
        .dash(testnet: false),
    ]

    /// What one pass of the mapper produces: the rows, the donut's segments and the ranking behind both.
    struct Review {
        let rows: [ForYouTokenListItem]
        let segments: [GaugeSegment]
        let slices: [String: PortfolioReviewSegmentPalette.Slice]
    }

    /// Runs the real mapper over one wallet model per balance, each holding its own blockchain.
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

    /// Mirrors `PortfolioReviewMapper`: aggregate, rank once, then build the rows and the donut from those same slices.
    func makeReview(_ holdings: [PortfolioReviewAggregator.TokenHolding]) -> Review {
        let (topHoldings, other, addressless) = PortfolioReviewAggregator.aggregate(holdings)
        let slices = SUT.slices(forRanked: topHoldings.chartableKeys)

        let rows = PortfolioRowBuilder().build(
            topHoldings: topHoldings,
            other: other,
            addressless: addressless,
            slices: slices,
            indicators: [:],
            timeframe: .day
        )
        let chart = PortfolioReviewMapper.ChartBuilder.build(topHoldings: topHoldings, other: other, slices: slices, noDataReason: .noAmount)

        return Review(rows: rows, segments: SummaryGaugeChart.segments(for: chart.loadedAssets), slices: slices)
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

// MARK: - Chart

private extension PortfolioReviewViewModel.ViewState.Chart {
    /// The fixtures always feed a positive total, so an empty result means the builder refused to chart.
    var loadedAssets: [SummaryGaugeAsset] {
        guard case .loaded(let assets, _, _) = self else { return [] }
        return assets
    }
}

// MARK: - Row list

private extension Array where Element == ForYouTokenListItem {
    /// Ids of the rows wearing a rank colour. The "Other" bucket has no token behind it and carries the neutral marker.
    var rankedRowIDs: [String] {
        filter { $0.assetRow.tokenItem != nil && $0.assetRow.indicatorColor != nil }.map(\.id)
    }
}
