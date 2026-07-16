//
//  PortfolioReviewAggregatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("PortfolioReviewAggregator")
struct PortfolioReviewAggregatorTests {
    // MARK: - Cross-network grouping

    @Test("Same asset across networks collapses into one group keyed by groupKey")
    func groupsByGroupKey() {
        let entries = [
            entry(id: "eth-main", groupKey: "ethereum", networkKey: "ethereum", fiat: 100),
            entry(id: "eth-arb", groupKey: "ethereum", networkKey: "arbitrum-one", fiat: 40),
            entry(id: "btc", groupKey: "bitcoin", networkKey: "bitcoin", fiat: 60),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.count == 2)
        #expect(result.other.isEmpty)

        let eth = result.topHoldings.first { $0.key == "ethereum" }
        #expect(eth?.entries.count == 2)
        #expect(eth?.networks.count == 2)
        #expect(eth?.fiat == 140)
    }

    @Test("Distinct groupKeys stay as separate groups (fallback-to-id case)")
    func groupsFallbackToId() {
        // Two custom tokens that share nothing: groupKey defaults to the per-entry id.
        let entries = [
            entry(id: "custom-a", groupKey: "custom-a", networkKey: "ethereum", fiat: 10),
            entry(id: "custom-b", groupKey: "custom-b", networkKey: "ethereum", fiat: 20),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.count == 2)
        #expect(Set(result.topHoldings.map(\.key)) == ["custom-a", "custom-b"])
    }

    // MARK: - Top-N + "Other" boundary

    @Test("Exactly four assets all become top holdings, Other is empty")
    func exactlyFourNoOther() {
        let entries = (1 ... 4).map { entry(id: "a\($0)", groupKey: "g\($0)", networkKey: "n\($0)", fiat: Decimal($0)) }

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.count == 4)
        #expect(result.other.isEmpty)
    }

    @Test("More than four assets collapse the tail into Other")
    func moreThanFourCollapses() {
        let entries = (1 ... 6).map { entry(id: "a\($0)", groupKey: "g\($0)", networkKey: "n\($0)", fiat: Decimal($0)) }

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.count == 4)
        #expect(result.other.count == 2)
        // Top holdings are ranked desc: 6, 5, 4, 3 — Other holds the two smallest: 2, 1.
        #expect(result.topHoldings.map(\.fiat) == [6, 5, 4, 3])
        #expect(Set(result.other.map(\.fiat)) == [2, 1])
    }

    // MARK: - Zero / nil fiat handling

    @Test("Positively-zero fiat is dropped, nil (loading) is kept")
    func dropsZeroKeepsNil() {
        let entries = [
            entry(id: "zero", groupKey: "zero", networkKey: "n1", fiat: 0),
            entry(id: "loading", groupKey: "loading", networkKey: "n2", fiat: nil, availability: .loading),
            entry(id: "held", groupKey: "held", networkKey: "n3", fiat: 50),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        let keys = Set(result.topHoldings.map(\.key))
        #expect(keys.contains("held"))
        #expect(keys.contains("loading"))
        #expect(!keys.contains("zero"))
    }

    // MARK: - Stable order on ties

    @Test("Equal fiat preserves first-seen order (stable sort)")
    func stableOrderOnTies() {
        let entries = [
            entry(id: "first", groupKey: "first", networkKey: "n1", fiat: 100),
            entry(id: "second", groupKey: "second", networkKey: "n2", fiat: 100),
            entry(id: "third", groupKey: "third", networkKey: "n3", fiat: 100),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.map(\.key) == ["first", "second", "third"])
    }

    // MARK: - Availability priority

    @Test("All-loading entries in a group resolve to .loading")
    func allLoadingIsLoading() {
        let entries = [
            entry(id: "a", groupKey: "g", networkKey: "n1", fiat: nil, availability: .loading),
            entry(id: "b", groupKey: "g", networkKey: "n2", fiat: nil, availability: .loading),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.first?.availability == .loading)
    }

    @Test("noAddress outranks unreachable and content within a group")
    func noAddressBeatsUnreachableAndContent() {
        let entries = [
            entry(id: "a", groupKey: "g", networkKey: "n1", fiat: 10, availability: .content),
            entry(id: "b", groupKey: "g", networkKey: "n2", fiat: nil, availability: .unreachable),
            entry(id: "c", groupKey: "g", networkKey: "n3", fiat: nil, availability: .noAddress),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.first?.availability == .noAddress)
    }

    @Test("unreachable outranks content within a group")
    func unreachableBeatsContent() {
        let entries = [
            entry(id: "a", groupKey: "g", networkKey: "n1", fiat: 10, availability: .content),
            entry(id: "b", groupKey: "g", networkKey: "n2", fiat: nil, availability: .unreachable),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)

        #expect(result.topHoldings.first?.availability == .unreachable)
    }

    // MARK: - Fiat sums

    @Test("Group fiat sums across networks and accounts; per-network fiat sums across accounts")
    func fiatSums() {
        let entries = [
            entry(id: "eth-acc1", groupKey: "ethereum", networkKey: "ethereum", fiat: 30),
            entry(id: "eth-acc2", groupKey: "ethereum", networkKey: "ethereum", fiat: 20),
            entry(id: "eth-arb", groupKey: "ethereum", networkKey: "arbitrum-one", fiat: 15),
        ]

        let result = PortfolioReviewAggregator.aggregate(entries)
        let eth = result.topHoldings.first { $0.key == "ethereum" }

        #expect(eth?.fiat == 65)

        let mainNet = eth?.networks.first { $0.sample.networkKey == "ethereum" }
        let arbNet = eth?.networks.first { $0.sample.networkKey == "arbitrum-one" }
        #expect(mainNet?.fiat == 50)
        #expect(arbNet?.fiat == 15)
        // Networks are ranked by fiat desc within the group.
        #expect(eth?.networks.map(\.fiat) == [50, 15])
    }
}

// MARK: - Fixtures

private extension PortfolioReviewAggregatorTests {
    func entry(
        id: String,
        groupKey: String,
        networkKey: String,
        fiat: Decimal?,
        crypto: Decimal? = nil,
        availability: PortfolioReviewAggregator.Availability = .content
    ) -> PortfolioReviewAggregator.Entry {
        PortfolioReviewAggregator.Entry(
            id: id,
            groupKey: groupKey,
            networkKey: networkKey,
            networkName: networkKey,
            symbol: groupKey,
            tokenItem: .blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)),
            crypto: crypto,
            fiat: fiat,
            availability: availability
        )
    }
}
