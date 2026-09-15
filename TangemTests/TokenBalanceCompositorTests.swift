//
//  TokenBalanceCompositorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("TokenBalanceCompositor")
struct TokenBalanceCompositorTests {
    // MARK: - Staking

    @Test("Staked funds add to the total")
    func stakedFundsAddToTheTotal() {
        let composed = staking.compose(.base(.loaded(10)), with: .loaded(3))

        #expect(composed.balance == 13)
    }

    @Test("A staking cache adds while it is loading, and dates the total")
    func stakingCacheAddsWhileLoading() {
        let composed = staking.compose(.base(.loaded(10)), with: .loading(cache))

        #expect(composed.balance == 13)
        #expect(composed.cacheDates == [cacheDate])
        #expect(composed.isLoading)
    }

    @Test("A failed staking source is left out while the base is healthy")
    func failedStakingIsLeftOutWhileTheBaseIsHealthy() {
        let composed = staking.compose(.base(.loaded(10)), with: .failure(cache))

        #expect(composed.balance == 10)
        #expect(composed.cacheDates.isEmpty)
    }

    @Test("A failed staking source counts once the base has failed too")
    func failedStakingCountsOnceTheBaseFailedToo() {
        let composed = staking.compose(.base(.failure(.init(balance: 10, date: baseDate)), balance: 10), with: .failure(cache))

        #expect(composed.balance == 13)
        #expect(composed.cacheDates == [cacheDate])
    }

    @Test("An empty staking source leaves the total untouched")
    func emptyStakingLeavesTheTotalUntouched() {
        let composed = staking.compose(.base(.loaded(10)), with: .empty(.noData))

        #expect(composed.balance == 10)
        #expect(!composed.isLoading)
    }

    // MARK: - Cardano staking

    @Test("A staked Cardano balance stands in for the total")
    func stakedCardanoBalanceStandsInForTheTotal() {
        let composed = cardanoStaking.compose(.base(.loaded(10)), with: .loaded(3))

        #expect(composed.balance == 3)
    }

    @Test("Cardano staking switched off leaves the total alone")
    func cardanoStakingSwitchedOffLeavesTheTotalAlone() {
        let composed = cardanoStaking.compose(.base(.loaded(10)), with: .loaded(0))

        #expect(composed.balance == 10)
    }

    /// Nothing is staked, so the base balance stands — but the staking source is still what was cached last,
    /// so it still dates the total.
    @Test("A zero Cardano staking cache dates the total it doesn't replace")
    func zeroCardanoStakingCacheDatesTheTotalItDoesNotReplace() {
        let composed = cardanoStaking.compose(.base(.loaded(10)), with: .loading(.init(balance: 0, date: cacheDate)))

        #expect(composed.balance == 10)
        #expect(composed.cacheDates == [cacheDate])
    }

    // MARK: - Factory

    @Test("The factory picks the chain's way of accounting for staked funds")
    func factoryPicksTheChainsWayOfAccountingForStakedFunds() {
        let cardano = makeStakingCompositor(blockchain: .cardano(extended: false))
        let ethereum = makeStakingCompositor(blockchain: .ethereum(testnet: false))

        #expect(cardano.compose(.base(.loaded(10)), with: .loaded(3)).balance == 3)
        #expect(ethereum.compose(.base(.loaded(10)), with: .loaded(3)).balance == 13)
    }
}

// MARK: - Test data

private extension TokenBalanceCompositorTests {
    var staking: StakingTokenBalanceCompositor {
        StakingTokenBalanceCompositor(balanceProvider: MutableTokenBalanceProviderMock(balance: 3))
    }

    var cardanoStaking: CardanoStakingTokenBalanceCompositor {
        CardanoStakingTokenBalanceCompositor(balanceProvider: MutableTokenBalanceProviderMock(balance: 3))
    }

    var baseDate: Date { Date(timeIntervalSince1970: 2_000) }
    var cacheDate: Date { Date(timeIntervalSince1970: 1_000) }
    var cache: TokenBalanceType.Cached { .init(balance: 3, date: cacheDate) }
}

// MARK: - Helpers

private extension TotalTokenBalanceComposition {
    static func base(_ state: TokenBalanceType, balance: Decimal? = nil) -> Self {
        .init(base: state, balance: balance ?? state.value ?? 0)
    }
}

private func makeStakingCompositor(blockchain: Blockchain) -> any TokenBalanceCompositor {
    StakingTokenBalanceCompositor.make(
        balanceProvider: MutableTokenBalanceProviderMock(balance: 3),
        tokenItem: .blockchain(.init(blockchain, derivationPath: nil))
    )
}
