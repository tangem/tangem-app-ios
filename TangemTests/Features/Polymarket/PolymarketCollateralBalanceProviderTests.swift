//
//  PolymarketCollateralBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket collateral balance")
struct PolymarketCollateralBalanceProviderTests {
    @Test("A balance that arrived is shown as loaded")
    func loadedBalanceIsShown() {
        let (sut, _, subject) = makeSUT()

        subject.send(.loaded(12.34))

        #expect(sut.balanceType == .loaded(12.34))
    }

    @Test("Nothing has arrived yet, so the balance is loading")
    func nothingYetIsLoading() {
        let (sut, _, _) = makeSUT()

        #expect(sut.balanceType == .loading(.none))
    }

    @Test("A request in flight keeps showing the last known balance")
    func aRequestInFlightKeepsTheCache() {
        let cached = CachedBalance(balance: 12.34, date: .distantPast)
        let (sut, _, subject) = makeSUT(cached: cached)

        subject.send(.loading)

        #expect(sut.balanceType == .loading(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("A failed request keeps showing the last known balance rather than blanking it")
    func aFailedRequestKeepsTheCache() {
        struct SomeError: Error {}
        let cached = CachedBalance(balance: 12.34, date: .distantPast)
        let (sut, _, subject) = makeSUT(cached: cached)

        subject.send(.failed(SomeError()))

        #expect(sut.balanceType == .failure(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("An unavailable balance drops the cache so the account shows a dash")
    func anUnavailableBalanceDropsTheCache() {
        let cached = CachedBalance(balance: 12.34, date: .distantPast)
        let (sut, _, subject) = makeSUT(cached: cached)

        subject.send(.unavailable)

        #expect(sut.balanceType == .empty(.custom))
    }

    @Test("A balance that arrived is written to the cache")
    func arrivedBalanceIsCached() {
        let (sut, repository, subject) = makeSUT()

        subject.send(.loaded(12.34))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.map(\.balance) == [12.34])
        }
    }

    @Test("The same balance twice is written once")
    func repeatedBalanceIsNotRewritten() {
        let (sut, repository, subject) = makeSUT()

        subject.send(.loaded(12.34))
        subject.send(.loaded(12.34))
        subject.send(.loaded(56.78))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.map(\.balance) == [12.34, 56.78])
        }
    }

    @Test("Only an arrived balance is cached, never loading or failure")
    func onlyArrivedBalancesAreCached() {
        struct SomeError: Error {}
        let (sut, repository, subject) = makeSUT()

        subject.send(.loading)
        subject.send(.failed(SomeError()))
        subject.send(.unavailable)

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.isEmpty)
        }
    }
}

// MARK: - Fixtures

private extension PolymarketCollateralBalanceProviderTests {
    typealias BalanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>

    func makeSUT(
        cached: CachedBalance? = nil
    ) -> (PolymarketCollateralBalanceProvider, TokenBalancesRepositorySpy, BalanceSubject) {
        let repository = TokenBalancesRepositorySpy(cached: cached)
        let subject = BalanceSubject(nil)
        let sut = PolymarketCollateralBalanceProvider(
            tokenItem: PolymarketUtilities.collateralTokenItem,
            tokenBalancesRepository: repository,
            balanceSubject: subject
        )

        return (sut, repository, subject)
    }
}

// MARK: - Doubles

private final class TokenBalancesRepositorySpy: TokenBalancesRepository {
    private(set) var storedBalances: [CachedBalance] = []

    private let cached: CachedBalance?

    init(cached: CachedBalance?) {
        self.cached = cached
    }

    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? {
        cached
    }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {
        storedBalances.append(balance)
    }
}
