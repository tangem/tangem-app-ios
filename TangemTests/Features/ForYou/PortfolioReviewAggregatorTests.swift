//
//  PortfolioReviewAggregatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("PortfolioReviewAggregator")
struct PortfolioReviewAggregatorTests {
    typealias SUT = PortfolioReviewAggregator
    typealias Availability = PortfolioReviewAggregator.Availability

    // MARK: - Ranking

    @Test("An asset addressless on every network is set aside")
    func fullyAddresslessAssetIsSetAside() {
        let result = SUT.aggregate([
            makeHolding(networkKey: "ethereum", availability: .noAddress),
            makeHolding(networkKey: "tron", availability: .noAddress),
        ])

        #expect(result.addressless.map(\.key) == [Self.groupKey])
        #expect(result.topHoldings.isEmpty)
        #expect(result.other.isEmpty)
    }

    @Test("A still-loading network keeps its asset out of the addressless bucket")
    func loadingNetworkKeepsAssetRanked() {
        let result = SUT.aggregate([
            makeHolding(networkKey: "ethereum", availability: .loading),
            makeHolding(networkKey: "tron", availability: .noAddress),
        ])

        #expect(result.addressless.isEmpty)
        #expect(result.topHoldings.map(\.availability) == [.loading])
    }

    @Test("A funded network outranks its addressless sibling")
    func fundedNetworkOutranksAddresslessSibling() {
        let result = SUT.aggregate([
            makeHolding(networkKey: "ethereum", availability: .content, amountInFiat: 100),
            makeHolding(networkKey: "tron", availability: .noAddress),
        ])

        #expect(result.addressless.isEmpty)
        #expect(result.topHoldings.map(\.amountInFiat) == [100])
    }

    // MARK: - Availability collapse

    @Test(
        "Collapses sibling networks to the most telling state",
        arguments: [
            (Availability.loading, Availability.noAddress, Availability.loading),
            (Availability.loading, Availability.unreachable, Availability.unreachable),
            (Availability.loading, Availability.noRate, Availability.noRate),
            (Availability.noAddress, Availability.content, Availability.content),
        ] as [(Availability, Availability, Availability)]
    )
    func collapsesSiblingNetworks(first: Availability, second: Availability, expected: Availability) {
        let result = SUT.aggregate([
            makeHolding(networkKey: "ethereum", availability: first),
            makeHolding(networkKey: "tron", availability: second),
        ])

        let groups = result.topHoldings + result.other + result.addressless

        #expect(groups.map(\.availability) == [expected])
    }

    // MARK: - Empty state

    @Test("Addressless holdings are listed past the empty-state display cap")
    func addresslessHoldingsSkipEmptyStateCap() {
        let addressed = (1 ... 5).map {
            makeHolding(groupKey: "coin\($0)", networkKey: "network\($0)", availability: .content, amountInFiat: 0)
        }
        let addressless = (1 ... 3).map {
            makeHolding(groupKey: "token\($0)", networkKey: "network\($0)", availability: .noAddress)
        }

        let keys = SUT.aggregateEmpty(addressed + addressless, count: 5).map(\.key)

        #expect(keys == ["coin1", "coin2", "coin3", "coin4", "coin5", "token1", "token2", "token3"])
    }
}

// MARK: - Helpers

private extension PortfolioReviewAggregatorTests {
    static let groupKey = "tether"

    func makeHolding(
        groupKey: String = Self.groupKey,
        networkKey: String,
        availability: Availability,
        amountInFiat: Decimal? = nil
    ) -> PortfolioReviewAggregator.TokenHolding {
        PortfolioReviewAggregator.TokenHolding(
            groupKey: groupKey,
            networkKey: networkKey,
            networkName: networkKey,
            symbol: "USDT",
            tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
            isCustom: false,
            amountInCrypto: nil,
            amountInFiat: amountInFiat,
            availability: availability
        )
    }
}
