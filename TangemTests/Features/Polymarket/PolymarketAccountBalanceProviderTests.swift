//
//  PolymarketAccountBalanceProviderTests.swift
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

private enum PolymarketBalanceFixtures {
    static let available = Decimal(string: "10.000813")!
    static let bets = Decimal(string: "7.792")!
    static let total = Decimal(string: "17.792813")!
}

private typealias BalanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>

private func makeSUT(
    kind: PolymarketAccountBalanceProvider.Kind,
    cached: CachedBalance? = nil
) -> (PolymarketAccountBalanceProvider, TokenBalancesRepositorySpy, BalanceSubject) {
    let repository = TokenBalancesRepositorySpy(cached: cached)
    let subject = BalanceSubject(nil)
    let sut = PolymarketAccountBalanceProvider(
        kind: kind,
        tokenItem: PolymarketUtilities.collateralTokenItem,
        tokenBalancesRepository: repository,
        balanceSubject: subject
    )

    return (sut, repository, subject)
}

private func makeBalance(
    available: Decimal = PolymarketBalanceFixtures.available,
    positionsValue: PolymarketBalance.PositionsValue
) -> PolymarketBalanceState {
    .loaded(PolymarketBalance(available: available, positionsValue: positionsValue))
}

// MARK: - The balance itself

@Suite("Polymarket balance")
struct PolymarketBalanceTests {
    @Test("The total holds both what is available and what sits in bets")
    func totalHoldsBothParts() {
        let balance = PolymarketBalance(
            available: PolymarketBalanceFixtures.available,
            positionsValue: .loaded(PolymarketBalanceFixtures.bets)
        )

        #expect(balance.total == PolymarketBalanceFixtures.total)
    }

    @Test("No bets at all is zero, not an unknown total")
    func noBetsIsZero() {
        let balance = PolymarketBalance(available: PolymarketBalanceFixtures.available, positionsValue: .loaded(.zero))

        #expect(balance.total == PolymarketBalanceFixtures.available)
    }

    @Test("Bets we could not read leave the total unknown while the available part survives")
    func unknownBetsLeaveTheTotalUnknown() {
        let balance = PolymarketBalance(available: PolymarketBalanceFixtures.available, positionsValue: .unknown)

        #expect(balance.total == nil)
        #expect(balance.available == PolymarketBalanceFixtures.available)
    }

    @Test("A total assembled from bets carried over from a previous round is shown but never remembered")
    func reusedBetsCountIntoTheTotalButNotIntoTheCache() {
        let balance = PolymarketBalance(
            available: PolymarketBalanceFixtures.available,
            positionsValue: .reused(PolymarketBalanceFixtures.bets)
        )

        #expect(balance.total == PolymarketBalanceFixtures.total)
        #expect(balance.freshTotal == nil)
    }

    @Test("Only a total built from bets that just arrived may be remembered")
    func freshBetsProduceARememberableTotal() {
        let balance = PolymarketBalance(
            available: PolymarketBalanceFixtures.available,
            positionsValue: .loaded(PolymarketBalanceFixtures.bets)
        )

        #expect(balance.freshTotal == PolymarketBalanceFixtures.total)
    }
}

// MARK: - The available part

@Suite("Polymarket available balance")
struct PolymarketAvailableBalanceProviderTests {
    @Test("A balance that arrived is shown as loaded")
    func loadedBalanceIsShown() {
        let (sut, _, subject) = makeSUT(kind: .available)

        subject.send(makeBalance(positionsValue: .unknown))

        #expect(sut.balanceType == .loaded(PolymarketBalanceFixtures.available))
    }

    @Test("Nothing has arrived yet, so the balance is loading")
    func nothingYetIsLoading() {
        let (sut, _, _) = makeSUT(kind: .available)

        #expect(sut.balanceType == .loading(.none))
    }

    @Test("A request in flight keeps showing the last known balance")
    func aRequestInFlightKeepsTheCache() {
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.available, date: .distantPast)
        let (sut, _, subject) = makeSUT(kind: .available, cached: cached)

        subject.send(.loading)

        #expect(sut.balanceType == .loading(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("A failed request keeps showing the last known balance rather than blanking it")
    func aFailedRequestKeepsTheCache() {
        struct SomeError: Error {}
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.available, date: .distantPast)
        let (sut, _, subject) = makeSUT(kind: .available, cached: cached)

        subject.send(.failed(SomeError()))

        #expect(sut.balanceType == .failure(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("An unavailable balance drops the cache so the account shows a dash")
    func anUnavailableBalanceDropsTheCache() {
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.available, date: .distantPast)
        let (sut, _, subject) = makeSUT(kind: .available, cached: cached)

        subject.send(.unavailable)

        #expect(sut.balanceType == .empty(.custom))
    }

    @Test("Bets that failed to load do not touch the available balance")
    func failedBetsDoNotTouchTheAvailableBalance() {
        let (sut, repository, subject) = makeSUT(kind: .available)

        subject.send(makeBalance(positionsValue: .unknown))

        withExtendedLifetime(sut) {
            #expect(sut.balanceType == .loaded(PolymarketBalanceFixtures.available))
            #expect(repository.storedBalances.map(\.balance) == [PolymarketBalanceFixtures.available])
        }
    }

    @Test("A balance that arrived is written to its own cache slot")
    func arrivedBalanceIsCached() {
        let (sut, repository, subject) = makeSUT(kind: .available)

        subject.send(makeBalance(positionsValue: .loaded(PolymarketBalanceFixtures.bets)))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.map(\.balance) == [PolymarketBalanceFixtures.available])
            #expect(repository.storedTypes == [.available])
        }
    }

    @Test("The same balance twice is written once")
    func repeatedBalanceIsNotRewritten() {
        let (sut, repository, subject) = makeSUT(kind: .available)

        subject.send(makeBalance(positionsValue: .unknown))
        subject.send(makeBalance(positionsValue: .unknown))
        subject.send(makeBalance(available: 56.78, positionsValue: .unknown))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.map(\.balance) == [PolymarketBalanceFixtures.available, 56.78])
        }
    }

    @Test("Only an arrived balance is cached, never loading or failure")
    func onlyArrivedBalancesAreCached() {
        struct SomeError: Error {}
        let (sut, repository, subject) = makeSUT(kind: .available)

        subject.send(.loading)
        subject.send(.failed(SomeError()))
        subject.send(.unavailable)

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.isEmpty)
        }
    }
}

// MARK: - The total

@Suite("Polymarket total balance")
struct PolymarketTotalBalanceProviderTests {
    @Test("A total that arrived is shown as loaded")
    func loadedTotalIsShown() {
        let (sut, _, subject) = makeSUT(kind: .total)

        subject.send(makeBalance(positionsValue: .loaded(PolymarketBalanceFixtures.bets)))

        #expect(sut.balanceType == .loaded(PolymarketBalanceFixtures.total))
    }

    @Test("Nothing has arrived yet, so the total is loading")
    func nothingYetIsLoading() {
        let (sut, _, _) = makeSUT(kind: .total)

        #expect(sut.balanceType == .loading(.none))
    }

    @Test("Bets that failed to load fall back to the last valid total, marked as stale")
    func failedBetsFallBackToTheLastValidTotal() {
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.total, date: .distantPast)
        let (sut, _, subject) = makeSUT(kind: .total, cached: cached)

        subject.send(makeBalance(positionsValue: .unknown))

        #expect(sut.balanceType == .failure(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("Bets that failed with no total ever known show a dash rather than the available part alone")
    func failedBetsWithoutACacheShowADash() {
        let (sut, _, subject) = makeSUT(kind: .total)

        subject.send(makeBalance(positionsValue: .unknown))

        #expect(sut.balanceType == .failure(.none))
    }

    @Test("A request in flight keeps showing the last known total")
    func aRequestInFlightKeepsTheCache() {
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.total, date: .distantPast)
        let (sut, _, subject) = makeSUT(kind: .total, cached: cached)

        subject.send(.loading)

        #expect(sut.balanceType == .loading(.init(balance: cached.balance, date: cached.date)))
    }

    @Test("An unavailable account has no total to show")
    func anUnavailableAccountHasNoTotal() {
        let (sut, _, subject) = makeSUT(kind: .total)

        subject.send(.unavailable)

        #expect(sut.balanceType == .empty(.custom))
    }

    @Test("A total assembled from fresh bets becomes the remembered one")
    func freshTotalIsCached() {
        let (sut, repository, subject) = makeSUT(kind: .total)

        subject.send(makeBalance(positionsValue: .loaded(PolymarketBalanceFixtures.bets)))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.map(\.balance) == [PolymarketBalanceFixtures.total])
            #expect(repository.storedTypes == [.total])
        }
    }

    @Test("A round that skipped the bets request never overwrites the remembered total")
    func reusedTotalIsNotCached() {
        let (sut, repository, subject) = makeSUT(kind: .total)

        subject.send(makeBalance(positionsValue: .reused(PolymarketBalanceFixtures.bets)))

        withExtendedLifetime(sut) {
            #expect(sut.balanceType == .loaded(PolymarketBalanceFixtures.total))
            #expect(repository.storedBalances.isEmpty)
        }
    }

    @Test("Loading, failure and unavailability are never remembered as a total")
    func onlyArrivedTotalsAreCached() {
        struct SomeError: Error {}
        let (sut, repository, subject) = makeSUT(kind: .total)

        subject.send(.loading)
        subject.send(.failed(SomeError()))
        subject.send(.unavailable)
        subject.send(makeBalance(positionsValue: .unknown))

        withExtendedLifetime(sut) {
            #expect(repository.storedBalances.isEmpty)
        }
    }

    @Test("The total reads its own cache slot, not the one the available balance uses")
    func theTotalKeepsItsOwnCacheSlot() {
        let cached = CachedBalance(balance: PolymarketBalanceFixtures.total, date: .distantPast)
        let (sut, repository, subject) = makeSUT(kind: .total, cached: cached)

        subject.send(.loading)
        _ = sut.balanceType

        withExtendedLifetime(sut) {
            #expect(repository.requestedTypes == [.total])
        }
    }
}

// MARK: - Doubles

private final class TokenBalancesRepositorySpy: TokenBalancesRepository {
    private(set) var storedBalances: [CachedBalance] = []
    private(set) var storedTypes: [CachedBalanceType] = []
    private(set) var requestedTypes: [CachedBalanceType] = []

    private let cached: CachedBalance?

    init(cached: CachedBalance?) {
        self.cached = cached
    }

    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? {
        requestedTypes.append(type)

        return cached
    }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {
        storedBalances.append(balance)
        storedTypes.append(type)
    }
}
