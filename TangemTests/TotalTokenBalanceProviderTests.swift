//
//  TotalTokenBalanceProviderTests.swift
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

@Suite("TotalTokenBalanceProviderTests")
struct TotalTokenBalanceProviderTests {
    @Test("Available cache is kept when staking is loading without cache")
    func availableCacheIsKeptWhenStakingIsLoadingWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, _, _) = makeSUT(available: .loading(cached), staking: .loading(nil))

        #expect(sut.balanceType == .loading(cached))
    }

    @Test("Loaded available is kept as loading cache when staking is loading without cache")
    func loadedAvailableIsKeptAsLoadingCacheWhenStakingIsLoadingWithoutCache() {
        let (sut, _, _) = makeSUT(available: .loaded(10), staking: .loading(nil))

        guard case .loading(.some(let cached)) = sut.balanceType else {
            Issue.record("Expected loading state with cache")
            return
        }

        #expect(cached.balance == 10)
    }

    @Test("Available failure cache is kept when staking fails without cache")
    func availableFailureCacheIsKeptWhenStakingFailsWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, _, _) = makeSUT(available: .failure(cached), staking: .failure(nil))

        #expect(sut.balanceType == .failure(cached))
    }

    @Test("Refresh never regresses from loading with cache to loading without cache")
    func refreshNeverRegressesFromLoadingWithCacheToLoadingWithoutCache() {
        let cached = TokenBalanceType.Cached(balance: 10, date: Date())
        let (sut, availableProvider, stakingProvider) = makeSUT(available: .loaded(10), staking: .loaded(2))

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
}

// MARK: - Helpers

private func makeSUT(
    available: TokenBalanceType,
    staking: TokenBalanceType
) -> (TotalTokenBalanceProvider, MutableTokenBalanceProviderMock, MutableTokenBalanceProviderMock) {
    let availableProvider = MutableTokenBalanceProviderMock(initialState: available)
    let stakingProvider = MutableTokenBalanceProviderMock(initialState: staking)

    let sut = TotalTokenBalanceProvider(
        tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
        availableBalanceProvider: availableProvider,
        stakingBalanceProvider: stakingProvider
    )

    return (sut, availableProvider, stakingProvider)
}
