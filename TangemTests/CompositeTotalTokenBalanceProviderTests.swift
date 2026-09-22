//
//  CompositeTotalTokenBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
import BlockchainSdk
@testable import Tangem

@Suite("CompositeTotalTokenBalanceProvider")
struct CompositeTotalTokenBalanceProviderTests {
    // MARK: - Table parity with the legacy fold

    @Test(arguments: TotalTokenBalanceFoldTable.rows)
    func foldMatchesSpec(row: FoldRow) {
        let (sut, _, _) = makeSUT(available: row.available, staking: row.staking, blockchain: .ethereum(testnet: false))

        row.expected.verify(against: sut.balanceType)
    }

    @Test(arguments: TotalTokenBalanceFoldTable.cardanoRows)
    func cardanoFoldMatchesSpec(row: FoldRow) {
        let (sut, _, _) = makeSUT(available: row.available, staking: row.staking, blockchain: .cardano(extended: false))

        row.expected.verify(against: sut.balanceType)
    }

    // MARK: - The publisher folds the same way as the synchronous getter

    @Test(arguments: TotalTokenBalanceFoldTable.rows)
    func publishedFoldMatchesSpec(row: FoldRow) throws {
        let (sut, _, _) = makeSUT(available: row.available, staking: row.staking, blockchain: .ethereum(testnet: false))

        row.expected.verify(against: try firstEmission(of: sut))
    }

    @Test(arguments: TotalTokenBalanceFoldTable.cardanoRows)
    func cardanoPublishedFoldMatchesSpec(row: FoldRow) throws {
        let (sut, _, _) = makeSUT(available: row.available, staking: row.staking, blockchain: .cardano(extended: false))

        row.expected.verify(against: try firstEmission(of: sut))
    }

    /// The compositors fold in order, so this pins that a substituting one keeps what follows it. Cardano
    /// staking substitutes, the third adds: confusing the two yields 2 or 15 instead of 5.
    @Test("Published fold keeps the substituting and the adding compositors in their roles")
    func publishedFoldKeepsSubstituteAndAdditionsInTheirRoles() throws {
        let (sut, _, _, _) = makeThreeContributorSUT(
            available: .loaded(10), staking: .loaded(3), third: .loaded(2),
            blockchain: .cardano(extended: false)
        )

        #expect(try firstEmission(of: sut) == .loaded(5))
    }

    @Test("Fabricated date comes from the injected clock when no contributor has a cache")
    func fabricatedDateComesFromInjectedClock() {
        let clock = Date(timeIntervalSince1970: 5_000)
        let tokenItem = makeTokenItem(.ethereum(testnet: false))
        let sut = CompositeTotalTokenBalanceProvider(
            tokenItem: tokenItem,
            base: MutableTokenBalanceProviderMock(initialState: .loaded(10)),
            compositors: [
                StakingTokenBalanceCompositor.make(
                    balanceProvider: MutableTokenBalanceProviderMock(initialState: .loading(nil)),
                    tokenItem: tokenItem
                ),
            ],
            now: { clock }
        )

        #expect(sut.balanceType == .loading(.init(balance: 10, date: clock)))
    }

    // MARK: - Formatted balance

    @Test(arguments: TotalTokenBalanceFoldTable.exactExpectationRows)
    func formattedBalanceMatchesLegacyProvider(row: FoldRow) {
        let (sut, _, _) = makeSUT(available: row.available, staking: row.staking, blockchain: .ethereum(testnet: false))
        let legacy = makeLegacySUT(available: row.available, staking: row.staking, blockchain: .ethereum(testnet: false))

        #expect(sut.formattedBalanceType == legacy.formattedBalanceType)
    }

    @Test("Arc native balance is displayed with six decimals")
    func arcNativeBalanceUsesSixDisplayDecimals() {
        let (sut, _, _) = makeSUT(available: .loaded(0.0000001), staking: .loaded(0), blockchain: .arc(testnet: false))

        guard case .loaded(let balance) = sut.formattedBalanceType else {
            Issue.record("Expected loaded formatted balance")
            return
        }

        let normalizedBalance = balance.replacingOccurrences(of: ",", with: ".")
        #expect(normalizedBalance.contains("0.000000"))
        #expect(!normalizedBalance.contains("0.0000001"))
    }

    @Test("Formatted publisher emits the formatted total, not the base")
    func formattedPublisherEmitsFormattedTotal() throws {
        let (sut, _, _) = makeSUT(available: .loaded(10), staking: .loaded(3), blockchain: .ethereum(testnet: false))

        var received: [FormattedTokenBalanceType] = []
        let subscription = sut.formattedBalanceTypePublisher.sink { received.append($0) }
        subscription.cancel()

        #expect(try #require(received.first) == sut.formattedBalanceType)
        #expect(sut.formattedBalanceType.value.contains("13"))
    }

    // MARK: - No contributors (Visa shape)

    @Test("Zero contributors fold equals the legacy fold with the .loaded(0) staking stub", arguments: Self.baseStates)
    func zeroContributorsFoldEqualsLegacyFoldWithLoadedZeroStub(base: TokenBalanceType) {
        let tokenItem = makeTokenItem(.ethereum(testnet: false))
        let sut = CompositeTotalTokenBalanceProvider(
            tokenItem: tokenItem,
            base: MutableTokenBalanceProviderMock(initialState: base),
            compositors: []
        )
        let legacy = TotalTokenBalanceProvider(
            tokenItem: tokenItem,
            availableBalanceProvider: MutableTokenBalanceProviderMock(initialState: base),
            stakingBalanceProvider: MutableTokenBalanceProviderMock(initialState: .loaded(0))
        )

        #expect(sut.balanceType == legacy.balanceType)
    }

    @Test("Publisher emits with zero contributors")
    func publisherEmitsWithZeroContributors() {
        let sut = CompositeTotalTokenBalanceProvider(
            tokenItem: makeTokenItem(.ethereum(testnet: false)),
            base: MutableTokenBalanceProviderMock(initialState: .loaded(10)),
            compositors: []
        )

        var received: [TokenBalanceType] = []
        let subscription = sut.balanceTypePublisher.sink { received.append($0) }
        subscription.cancel()

        #expect(received == [.loaded(10)])
    }

    // MARK: - Three contributors (future staking/yield shape)

    @Test("Three loaded contributors sum")
    func threeLoadedContributorsSum() {
        let (sut, _, _, _) = makeThreeContributorSUT(available: .loaded(10), staking: .loaded(3), third: .loaded(2))

        #expect(sut.balanceType == .loaded(15))
    }

    @Test("Third contributor cache participates while it is loading")
    func thirdContributorCacheParticipatesWhileLoading() {
        let thirdCache = TokenBalanceType.Cached(balance: 2, date: TotalTokenBalanceFoldTable.olderDate)
        let (sut, _, _, _) = makeThreeContributorSUT(available: .loaded(10), staking: .loaded(3), third: .loading(thirdCache))

        #expect(sut.balanceType == .loading(.init(balance: 15, date: TotalTokenBalanceFoldTable.olderDate)))
    }

    @Test("Third contributor failure is ignored while the base is healthy")
    func thirdContributorFailureIsIgnoredWhileBaseHealthy() {
        let thirdCache = TokenBalanceType.Cached(balance: 2, date: TotalTokenBalanceFoldTable.olderDate)
        let (sut, _, _, _) = makeThreeContributorSUT(available: .loaded(10), staking: .loaded(3), third: .failure(thirdCache))

        #expect(sut.balanceType == .loaded(13))
    }

    @Test("The base cache date wins over every contributor cache date")
    func baseCacheDateWinsOverContributorCacheDates() {
        let (sut, _, _, _) = makeThreeContributorSUT(
            available: .loading(TotalTokenBalanceFoldTable.availableCache),
            staking: .loading(TotalTokenBalanceFoldTable.stakingOlderCache),
            third: .loading(.init(balance: 2, date: TotalTokenBalanceFoldTable.newerDate))
        )

        #expect(sut.balanceType == .loading(.init(balance: 14, date: TotalTokenBalanceFoldTable.availableCacheDate)))
    }

    @Test("The oldest contributor cache dates the total when the base has no cache")
    func oldestContributorCacheDatesTheTotalWithoutABaseCache() {
        let (sut, _, _, _) = makeThreeContributorSUT(
            available: .loaded(10),
            staking: .loading(TotalTokenBalanceFoldTable.stakingOlderCache),
            third: .loading(.init(balance: 2, date: TotalTokenBalanceFoldTable.newerDate))
        )

        #expect(sut.balanceType == .loading(.init(balance: 17, date: TotalTokenBalanceFoldTable.olderDate)))
    }

    @Test("Cardano staking replaces the base, then an additive third contributor adds")
    func cardanoStakingReplacesThenThirdContributorAdds() {
        let (nonZeroStaked, _, _, _) = makeThreeContributorSUT(
            available: .loaded(10), staking: .loaded(3), third: .loaded(2),
            blockchain: .cardano(extended: false)
        )
        let (zeroStaked, _, _, _) = makeThreeContributorSUT(
            available: .loaded(10), staking: .loaded(0), third: .loaded(2),
            blockchain: .cardano(extended: false)
        )

        #expect(nonZeroStaked.balanceType == .loaded(5))
        #expect(zeroStaked.balanceType == .loaded(12))
    }

    // MARK: - Publisher-sequence invariants (ported from TotalTokenBalanceProviderTests)

    @Test("Available cache is kept when staking is loading without cache")
    func availableCacheIsKeptWhenStakingIsLoadingWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, _, _) = makeSUT(available: .loading(cached), staking: .loading(nil), blockchain: .ethereum(testnet: false))

        #expect(sut.balanceType == .loading(cached))
    }

    @Test("Loaded available is kept as loading cache when staking is loading without cache")
    func loadedAvailableIsKeptAsLoadingCacheWhenStakingIsLoadingWithoutCache() {
        let (sut, _, _) = makeSUT(available: .loaded(10), staking: .loading(nil), blockchain: .ethereum(testnet: false))

        guard case .loading(.some(let cached)) = sut.balanceType else {
            Issue.record("Expected loading state with cache")
            return
        }

        #expect(cached.balance == 10)
    }

    @Test("Available failure cache is kept when staking fails without cache")
    func availableFailureCacheIsKeptWhenStakingFailsWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, _, _) = makeSUT(available: .failure(cached), staking: .failure(nil), blockchain: .ethereum(testnet: false))

        #expect(sut.balanceType == .failure(cached))
    }

    @Test("Refresh never regresses from loading with cache to loading without cache")
    func refreshNeverRegressesFromLoadingWithCacheToLoadingWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, availableProvider, stakingProvider) = makeSUT(available: .loaded(10), staking: .loaded(2), blockchain: .ethereum(testnet: false))

        var received: [TokenBalanceType] = []
        let subscription = sut.balanceTypePublisher.sink { received.append($0) }

        availableProvider.updateBalance(.loading(cached))
        stakingProvider.updateBalance(.loading(nil))
        availableProvider.updateBalance(.loaded(10))
        stakingProvider.updateBalance(.loaded(2))
        subscription.cancel()

        #expect(!received.contains(.loading(nil)))
        #expect(received.last == .loaded(12))
    }

    @Test("Refresh never regresses with three contributors")
    func refreshNeverRegressesWithThreeContributors() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, availableProvider, stakingProvider, thirdProvider) = makeThreeContributorSUT(
            available: .loaded(10), staking: .loaded(2), third: .loaded(1)
        )

        var received: [TokenBalanceType] = []
        let subscription = sut.balanceTypePublisher.sink { received.append($0) }

        availableProvider.updateBalance(.loading(cached))
        stakingProvider.updateBalance(.loading(nil))
        thirdProvider.updateBalance(.loading(nil))
        availableProvider.updateBalance(.loaded(10))
        stakingProvider.updateBalance(.loaded(2))
        thirdProvider.updateBalance(.loaded(1))
        subscription.cancel()

        #expect(!received.contains(.loading(nil)))
        #expect(received.last == .loaded(13))
    }
}

// MARK: - Test data

private extension CompositeTotalTokenBalanceProviderTests {
    static let baseStates: [TokenBalanceType] = [
        .empty(.noData),
        .loading(nil),
        .loading(TotalTokenBalanceFoldTable.availableCache),
        .failure(nil),
        .failure(TotalTokenBalanceFoldTable.availableCache),
        .loaded(10),
    ]
}

// MARK: - Helpers

private func makeTokenItem(_ blockchain: Blockchain) -> TokenItem {
    .blockchain(.init(blockchain, derivationPath: nil))
}

private func firstEmission(of provider: TokenBalanceProvider) throws -> TokenBalanceType {
    var received: [TokenBalanceType] = []
    let subscription = provider.balanceTypePublisher.sink { received.append($0) }
    subscription.cancel()

    return try #require(received.first, "The balance publisher did not emit")
}

private func makeLegacySUT(
    available: TokenBalanceType,
    staking: TokenBalanceType,
    blockchain: Blockchain
) -> TotalTokenBalanceProvider {
    TotalTokenBalanceProvider(
        tokenItem: makeTokenItem(blockchain),
        availableBalanceProvider: MutableTokenBalanceProviderMock(initialState: available),
        stakingBalanceProvider: MutableTokenBalanceProviderMock(initialState: staking)
    )
}

private func makeSUT(
    available: TokenBalanceType,
    staking: TokenBalanceType,
    blockchain: Blockchain
) -> (CompositeTotalTokenBalanceProvider, MutableTokenBalanceProviderMock, MutableTokenBalanceProviderMock) {
    let availableProvider = MutableTokenBalanceProviderMock(initialState: available)
    let stakingProvider = MutableTokenBalanceProviderMock(initialState: staking)
    let tokenItem = makeTokenItem(blockchain)

    let sut = CompositeTotalTokenBalanceProvider(
        tokenItem: tokenItem,
        base: availableProvider,
        compositors: [StakingTokenBalanceCompositor.make(balanceProvider: stakingProvider, tokenItem: tokenItem)]
    )

    return (sut, availableProvider, stakingProvider)
}

private func makeThreeContributorSUT(
    available: TokenBalanceType,
    staking: TokenBalanceType,
    third: TokenBalanceType,
    blockchain: Blockchain = .ethereum(testnet: false)
) -> (CompositeTotalTokenBalanceProvider, MutableTokenBalanceProviderMock, MutableTokenBalanceProviderMock, MutableTokenBalanceProviderMock) {
    let availableProvider = MutableTokenBalanceProviderMock(initialState: available)
    let stakingProvider = MutableTokenBalanceProviderMock(initialState: staking)
    let thirdProvider = MutableTokenBalanceProviderMock(initialState: third)
    let tokenItem = makeTokenItem(blockchain)

    let sut = CompositeTotalTokenBalanceProvider(
        tokenItem: tokenItem,
        base: availableProvider,
        compositors: [
            StakingTokenBalanceCompositor.make(balanceProvider: stakingProvider, tokenItem: tokenItem),
            StakingTokenBalanceCompositor(balanceProvider: thirdProvider),
        ]
    )

    return (sut, availableProvider, stakingProvider, thirdProvider)
}
