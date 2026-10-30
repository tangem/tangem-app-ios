//
//  CollectiblesUsdcBalanceProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemCollectibles
import TangemTestKit
import Testing
@testable import Tangem

@Suite("CollectiblesUsdcBalanceProvider")
final class CollectiblesUsdcBalanceProviderTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesUsdcBalanceProvider

    @Test("The vault USDC is cached apart from an ordinary USDC wallet model")
    func cacheKeyIsTheCollectiblesDerivation() throws {
        guard case .token(let usdcToken, _) = CollectiblesChainEnvironment.usdcTokenItem else {
            Issue.record("The vault USDC token item is expected to be a token")
            return
        }

        let ordinaryNetwork = BlockchainNetwork(CollectiblesChainEnvironment.blockchain, derivationPath: nil)
        let ordinaryUsdcTokenItem = TokenItem.token(usdcToken, ordinaryNetwork)

        #expect(WalletModelId(tokenItem: CollectiblesChainEnvironment.usdcTokenItem).id != WalletModelId(tokenItem: ordinaryUsdcTokenItem).id)
    }

    @Test("A loaded balance is converted from base units by the token decimals")
    func loadedBalanceIsConverted() {
        let (sut, _, subject) = makeSUT()

        subject.send(.loaded(1_500_000))

        #expect(sut.balanceType == .loaded(1.5))
    }

    @Test("No vault means an empty balance, not a zero")
    func unavailableReadsAsEmpty() {
        let (sut, _, subject) = makeSUT()

        subject.send(.unavailable)

        #expect(sut.balanceType == .empty(.custom))
    }

    @Test("Loading surfaces the cached balance", arguments: [nil, CollectiblesBalanceState.loading] as [CollectiblesBalanceState?])
    func loadingSurfacesCache(state: CollectiblesBalanceState?) {
        let (sut, _, subject) = makeSUT(cached: Constants.cached)

        subject.send(state)

        #expect(sut.balanceType == .loading(.init(balance: Constants.cached.balance, date: Constants.cached.date)))
    }

    @Test("A failure surfaces the cached balance")
    func failureSurfacesCache() {
        let (sut, _, subject) = makeSUT(cached: Constants.cached)

        subject.send(.failed(TestError.chain))

        #expect(sut.balanceType == .failure(.init(balance: Constants.cached.balance, date: Constants.cached.date)))
    }

    @Test("The publisher mirrors every state the vault reports")
    func publisherMirrorsStates() {
        let (sut, _, subject) = makeSUT()
        var recorded: [TokenBalanceType] = []
        let cancellable = sut.balanceTypePublisher.sink { recorded.append($0) }

        withExtendedLifetime(sut) {
            subject.send(.loading)
            subject.send(.loaded(2_000_000))
        }

        #expect(recorded == [.loading(nil), .loading(nil), .loaded(2)])
        cancellable.cancel()
    }

    @Test("Only a loaded balance is stored for the next cold start")
    func onlyLoadedBalanceIsStored() {
        let (sut, repository, subject) = makeSUT()

        withExtendedLifetime(sut) {
            subject.send(.loading)
            subject.send(.unavailable)
            subject.send(.failed(TestError.chain))
            subject.send(.loaded(2_000_000))
        }

        #expect(repository.storedBalances.map(\.balance) == [2])
        #expect(repository.storedTypes == [.available])
    }

    @Test("Repeating a loaded balance stores it once, a new one stores again")
    func repeatedBalanceIsStoredOnce() {
        let (sut, repository, subject) = makeSUT()

        withExtendedLifetime(sut) {
            subject.send(.loaded(1_000_000))
            subject.send(.loaded(1_000_000))
            subject.send(.loaded(3_000_000))
        }

        #expect(repository.storedBalances.map(\.balance) == [1, 3])
    }
}

// MARK: - Helpers

private extension CollectiblesUsdcBalanceProviderTests {
    typealias BalanceSubject = CurrentValueSubject<CollectiblesBalanceState?, Never>

    enum Constants {
        static let cached = CachedBalance(balance: 2.5, date: Date(timeIntervalSince1970: 1_700_000_000))
    }

    func makeSUT(cached: CachedBalance? = nil) -> (SUT, TokenBalancesRepositorySpy, BalanceSubject) {
        let repository = TokenBalancesRepositorySpy(cached: cached)
        let subject = BalanceSubject(nil)
        let sut = SUT(
            tokenItem: CollectiblesChainEnvironment.usdcTokenItem,
            tokenBalancesRepository: repository,
            balanceSubject: subject
        )

        return (trackForMemoryLeaks(sut), repository, subject)
    }
}

// MARK: - Doubles

private enum TestError: Error {
    case chain
}

private final class TokenBalancesRepositorySpy: TokenBalancesRepository {
    private(set) var storedBalances: [CachedBalance] = []
    private(set) var storedTypes: [CachedBalanceType] = []

    private let cached: CachedBalance?

    init(cached: CachedBalance?) {
        self.cached = cached
    }

    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? {
        cached
    }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {
        storedBalances.append(balance)
        storedTypes.append(type)
    }
}
