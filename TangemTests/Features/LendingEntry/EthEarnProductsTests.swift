//
//  EthEarnProductsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemStaking
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

    @Test("The banner waits until both rates and the lending position are known")
    func bannerWaitsForEveryRead() {
        #expect(Self.banner(staking: .loading) == .loading)
        #expect(Self.banner(lendingApy: .loading) == .loading)
        #expect(Self.banner(lendingPosition: .loading) == .loading)
    }

    @Test("An open position doesn't wait for the Lending rate: Aave joins the products to start once the rate arrives")
    func activePositionDoesNotWaitForRate() throws {
        let banner = try #require(Self.banner(staking: .staked(balance: 2, apy: Self.stakingApy), lendingApy: .loading))

        #expect(Self.ids(of: banner) == Ids(active: [.pooledStaking], inactive: []))
    }

    @Test(
        "A staking row opens only what the token page would: the region sheet when blocked, nothing while staking is unavailable",
        arguments: [
            (StakingManagerState.unavailableInRegion(cached: nil), EthEarnProducts.StakingRoute?.some(.regionUnavailable)),
            (.loadingError("error", cached: nil), nil),
            (.loading(cached: nil), nil),
            (.notEnabled, nil),
        ]
    )
    func stakingRoute(state: StakingManagerState, route: EthEarnProducts.StakingRoute?) {
        #expect(EthEarnProducts.stakingRoute(for: state) == route)
    }

    @Test("A product whose rate couldn't be read is left out of the banner and the picker")
    func unreadableRateIsLeftOut() throws {
        let stakingOnly = try #require(Self.banner(lendingApy: .failure(StubError())))
        let lendingOnly = try #require(Self.banner(staking: .unavailable))

        #expect(Self.ids(of: stakingOnly) == Ids(inactive: [.pooledStaking], best: .pooledStaking))
        #expect(Self.ids(of: lendingOnly) == Ids(inactive: [.lendingOnAave], best: .lendingOnAave))
    }

    @Test("With both rates known the Earn banner shows the higher one, whichever product it comes from")
    func bannerShowsHigherRate() throws {
        let stakingHigher = try #require(Self.banner(staking: .available(apy: Self.stakingApy), lendingApy: .success(Self.lendingApy)))
        let lendingHigher = try #require(Self.banner(staking: .available(apy: Self.lendingApy), lendingApy: .success(Self.stakingApy)))

        #expect(Self.ids(of: stakingHigher) == Ids(inactive: [.pooledStaking, .lendingOnAave], best: .pooledStaking))
        #expect(Self.ids(of: lendingHigher) == Ids(inactive: [.pooledStaking, .lendingOnAave], best: .lendingOnAave))
    }

    @Test("Without staking, a lending rate and a lending position there is no banner")
    func noProductsNoBanner() {
        #expect(Self.banner(staking: .unavailable, lendingApy: .failure(StubError())) == nil)
    }

    @Test("A staked position turns the banner into Yield enabled and keeps lending as the product to start")
    func stakedPositionEnablesYield() throws {
        let banner = try #require(Self.banner(staking: .staked(balance: 2, apy: Self.stakingApy)))

        #expect(Self.ids(of: banner) == Ids(active: [.pooledStaking], inactive: [.lendingOnAave]))
        #expect(Self.positions(of: banner) == [EthEarnProducts.Position(id: .pooledStaking, balance: 2, apy: Self.stakingApy)])
    }

    @Test("A lending position keeps the rate before the performance fee, like staking, and moves lending out of the products to start")
    func lendingPositionEnablesYield() throws {
        let banner = try #require(Self.banner(lendingPosition: .success(Decimal(5) / 10)))

        #expect(Self.ids(of: banner) == Ids(active: [.lendingOnAave], inactive: [.pooledStaking]))
        #expect(Self.positions(of: banner) == [EthEarnProducts.Position(id: .lendingOnAave, balance: Decimal(5) / 10, apy: Self.lendingApy)])
    }

    @Test("With both positions open there is nothing left to start")
    func bothPositionsLeaveNothingToStart() throws {
        let banner = try #require(Self.banner(staking: .staked(balance: 2, apy: Self.stakingApy), lendingPosition: .success(1)))

        #expect(Self.ids(of: banner) == Ids(active: [.pooledStaking, .lendingOnAave], inactive: []))
    }

    @Test("A lending position stays visible when its rate can't be read, without a rate")
    func lendingPositionWithoutRate() throws {
        let banner = try #require(Self.banner(staking: .unavailable, lendingApy: .failure(StubError()), lendingPosition: .success(1)))

        #expect(Self.positions(of: banner) == [EthEarnProducts.Position(id: .lendingOnAave, balance: 1, apy: nil)])
    }
}

// MARK: - Helpers

private extension EthEarnProductsTests {
    static let stakingApy = Decimal(31) / 1000
    static let lendingApy = Decimal(24) / 1000

    struct Ids: Equatable {
        var active: [EarnYieldPickerProduct.ID] = []
        let inactive: [EarnYieldPickerProduct.ID]
        var best: EarnYieldPickerProduct.ID?
    }

    static func banner(
        staking: EthEarnProducts.Staking = .available(apy: stakingApy),
        lendingApy: LoadingResult<Decimal, Error> = .success(lendingApy),
        lendingPosition: LoadingResult<Decimal, Never> = .success(0)
    ) -> EthEarnProducts.Banner? {
        EthEarnProducts.banner(staking: staking, lendingApy: lendingApy, lendingPosition: lendingPosition)
    }

    static func ids(of banner: EthEarnProducts.Banner) -> Ids {
        switch banner {
        case .loading:
            Ids(inactive: [])
        case .earn(let products, let best):
            Ids(inactive: products.map(\.id), best: best.id)
        case .yieldEnabled(let active, let inactive):
            Ids(active: active.map(\.id), inactive: inactive.map(\.id))
        }
    }

    static func positions(of banner: EthEarnProducts.Banner) -> [EthEarnProducts.Position] {
        guard case .yieldEnabled(let active, _) = banner else {
            return []
        }

        return active
    }
}

// MARK: - Stubs

private struct StubError: Error {}
