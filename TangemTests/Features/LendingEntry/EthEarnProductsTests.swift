//
//  EthEarnProductsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("ETH earn products")
struct EthEarnProductsTests {
    @Test("The best product is the one with the highest rate, whichever product it is")
    func bestRateWins() throws {
        let stakingLeads = EthEarnProducts.make(stakingApy: Decimal(31) / 1000, lendingApy: Decimal(24) / 1000)
        let lendingLeads = EthEarnProducts.make(stakingApy: Decimal(31) / 1000, lendingApy: Decimal(35) / 1000)

        let stakingBest = try #require(EthEarnProducts.bestProduct(in: stakingLeads))
        let lendingBest = try #require(EthEarnProducts.bestProduct(in: lendingLeads))

        #expect(stakingBest.id == .pooledStaking)
        #expect(stakingBest.apy == Decimal(31) / 1000)
        #expect(lendingBest.id == .lendingOnAave)
        #expect(lendingBest.apy == Decimal(35) / 1000)
    }

    @Test("A product without a rate is left out, so staking that is unavailable drops its chip")
    func productWithoutRateIsLeftOut() {
        let lendingOnly = EthEarnProducts.make(stakingApy: nil, lendingApy: Decimal(24) / 1000)
        let stakingOnly = EthEarnProducts.make(stakingApy: Decimal(31) / 1000, lendingApy: nil)

        #expect(lendingOnly.map(\.id) == [.lendingOnAave])
        #expect(stakingOnly.map(\.id) == [.pooledStaking])
        #expect(EthEarnProducts.make(stakingApy: nil, lendingApy: nil).isEmpty)
    }

    @Test("Each product carries its own performance fee from the PRD")
    func performanceFees() {
        let products = EthEarnProducts.make(stakingApy: Decimal(31) / 1000, lendingApy: Decimal(24) / 1000)

        #expect(products.map(\.performanceFee) == [Decimal(8) / 100, Decimal(15) / 100])
    }

    @Test("A staked position keeps the staking card, whatever the lending rate")
    func stakedPositionKeepsStakingCard() {
        #expect(EthEarnProducts.banner(staking: .staked, lendingApy: .success(Self.lendingApy)) == nil)
    }

    @Test("The banner waits until both rates are known")
    func bannerWaitsForBothRates() {
        #expect(EthEarnProducts.banner(staking: .loading, lendingApy: .success(Self.lendingApy)) == .loading)
        #expect(EthEarnProducts.banner(staking: .available(apy: Self.stakingApy), lendingApy: .loading) == .loading)
    }

    @Test("A product whose rate couldn't be read is left out of the banner and the picker")
    func unreadableRateIsLeftOut() throws {
        let stakingOnly = try #require(EthEarnProducts.banner(staking: .available(apy: Self.stakingApy), lendingApy: .failure(StubError())))
        let lendingOnly = try #require(EthEarnProducts.banner(staking: .unavailable, lendingApy: .success(Self.lendingApy)))

        #expect(Self.ids(of: stakingOnly) == Ids(products: [.pooledStaking], best: .pooledStaking))
        #expect(Self.ids(of: lendingOnly) == Ids(products: [.lendingOnAave], best: .lendingOnAave))
    }

    @Test("With both rates known the Earn banner shows the higher one, whichever product it comes from")
    func bannerShowsHigherRate() throws {
        let stakingHigher = try #require(EthEarnProducts.banner(staking: .available(apy: Self.stakingApy), lendingApy: .success(Self.lendingApy)))
        let lendingHigher = try #require(EthEarnProducts.banner(staking: .available(apy: Self.lendingApy), lendingApy: .success(Self.stakingApy)))

        #expect(Self.ids(of: stakingHigher) == Ids(products: [.pooledStaking, .lendingOnAave], best: .pooledStaking))
        #expect(Self.ids(of: lendingHigher) == Ids(products: [.pooledStaking, .lendingOnAave], best: .lendingOnAave))
    }

    @Test("Without staking and without a lending rate there is no banner")
    func noProductsNoBanner() {
        #expect(EthEarnProducts.banner(staking: .unavailable, lendingApy: .failure(StubError())) == nil)
    }
}

// MARK: - Helpers

private extension EthEarnProductsTests {
    static let stakingApy = Decimal(31) / 1000
    static let lendingApy = Decimal(24) / 1000

    struct Ids: Equatable {
        let products: [EarnYieldPickerProduct.ID]
        let best: EarnYieldPickerProduct.ID?
    }

    static func ids(of banner: EthEarnProducts.Banner) -> Ids {
        switch banner {
        case .loading:
            Ids(products: [], best: nil)
        case .earn(let products, let best):
            Ids(products: products.map(\.id), best: best.id)
        }
    }
}

// MARK: - Stubs

private struct StubError: Error {}
