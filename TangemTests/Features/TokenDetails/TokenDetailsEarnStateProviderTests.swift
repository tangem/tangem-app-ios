//
//  TokenDetailsEarnStateProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import TangemStaking
@testable import Tangem

@Suite("Token details Earn state", .timeLimit(.minutes(1)))
struct TokenDetailsEarnStateProviderTests {
    @Test("A loaded lending rate shows the Earn banner when staking is not offered")
    func lendingRateShowsEarnBanner() async throws {
        let state = try await settledState(of: makeSUT(rates: [.success(Self.rate)]))

        guard case .earn(.earn(let item)) = state else {
            Issue.record("Expected the Earn banner, got \(state)")
            return
        }

        #expect(item.title == "Earn")
    }

    @Test("A rate the main screen already loaded shows on the ETH page without asking for it again")
    func loadedRateShowsAtOnce() async throws {
        let rateRepository = RateStub(results: [.failure(RateError())], loadedApy: Self.rate)

        let state = try await settledState(of: makeSUT(rateRepository: rateRepository))

        guard case .earn(.earn) = state else {
            Issue.record("Expected the Earn banner, got \(state)")
            return
        }

        #expect(rateRepository.refreshCalls == 0)
    }

    @Test("A failed lending rate leaves the staking state as it is")
    func failedRateFallsBackToStaking() async throws {
        let state = try await settledState(of: makeSUT(rates: [.failure(RateError())]))

        guard case .staking(.notEnabled) = state else {
            Issue.record("Expected the staking state, got \(state)")
            return
        }
    }

    @Test("Refreshing after a failed lending rate brings the Earn banner back")
    func refreshAfterFailedRate() async throws {
        let sut = makeSUT(rates: [.failure(RateError()), .success(Self.rate)])
        _ = try await settledState(of: sut)

        sut.refresh()

        _ = try await firstState(of: sut) { state in
            if case .earn(.earn) = state {
                return true
            }

            return false
        }
    }

    @Test(
        "A staking error keeps the user's cached stake among the active products",
        arguments: [
            StakingManagerState.loadingError("error", cached: Self.cachedStake),
            .unavailableInRegion(cached: Self.cachedStake),
        ]
    )
    func stakingErrorWithCachedStake(staking: StakingManagerState) async throws {
        let state = try await settledState(of: makeSUT(rates: [.success(Self.rate)], staking: staking))

        guard case .earn(.yieldEnabled(let item)) = state else {
            Issue.record("Expected Yield enabled, got \(state)")
            return
        }

        #expect(item.activeCount == "1 active")
    }

    @Test("A staking error without a cached stake offers Lending on Aave")
    func stakingErrorWithoutStake() async throws {
        let cached = CachedStakingManagerState(rewardType: .apy, apy: 0.03, stakeState: .availableToStake, date: Date())
        let state = try await settledState(of: makeSUT(rates: [.success(Self.rate)], staking: .loadingError("error", cached: cached)))

        guard case .earn(.earn) = state else {
            Issue.record("Expected the Earn banner, got \(state)")
            return
        }
    }

    @Test("A lending position shows Yield enabled with one active product")
    func lendingPositionShowsYieldEnabled() async throws {
        let sut = makeSUT(rates: [.success(Self.rate)], lendingPositions: [.success(Decimal(3) / 2)])

        let state = try await settledState(of: sut)

        guard case .earn(.yieldEnabled(let item)) = state else {
            Issue.record("Expected Yield enabled, got \(state)")
            return
        }

        #expect(item.activeCount == "1 active")
    }

    @Test("A failed re-read keeps the last lending position instead of hiding it behind the Earn banner")
    func failedPositionReadKeepsLastPosition() async throws {
        let sut = makeSUT(rates: [.success(Self.rate)], lendingPositions: [.success(Decimal(3) / 2), .failure(RateError())])
        _ = try await settledState(of: sut)
        let (states, continuation) = AsyncStream.makeStream(of: TokenDetailsEarnStateProvider.State.self)
        let subscription = sut.statePublisher.sink { continuation.yield($0) }
        var iterator = states.makeAsyncIterator()
        _ = await iterator.next()

        sut.refresh()
        let state = await iterator.next()
        subscription.cancel()

        guard case .earn(.yieldEnabled(let item)) = state else {
            Issue.record("Expected Yield enabled, got \(String(describing: state))")
            return
        }

        #expect(item.activeCount == "1 active")
    }
}

// MARK: - Helpers

private extension TokenDetailsEarnStateProviderTests {
    static let rate = Decimal(147) / 10_000
    static let cachedStake = CachedStakingManagerState(rewardType: .apy, apy: 0.03, stakeState: .staked(balance: 1), date: Date())

    func makeSUT(
        rates: [Result<Decimal, Error>],
        staking: StakingManagerState = .notEnabled,
        lendingPositions: [Result<Decimal, Error>]? = nil
    ) -> TokenDetailsEarnStateProvider {
        makeSUT(rateRepository: RateStub(results: rates), staking: staking, lendingPositions: lendingPositions)
    }

    func makeSUT(
        rateRepository: RateStub,
        staking: StakingManagerState = .notEnabled,
        lendingPositions: [Result<Decimal, Error>]? = nil
    ) -> TokenDetailsEarnStateProvider {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stakingManagerStateMock = staking
        walletModel.lendingModuleReaderMock = lendingPositions.map { ReaderStub(positions: PositionStub(results: $0)) }

        return TokenDetailsEarnStateProvider(
            walletModel: walletModel,
            userWalletInfo: UserWalletInfo(
                name: "Test",
                id: UserWalletId(value: Data([0x01])),
                config: UserWalletConfigStub(),
                backupState: .valid,
                refcode: nil,
                signerFactory: TangemSignerFactory(),
                emailDataProvider: EmailDataProviderStub()
            ),
            coordinator: nil,
            rateRepository: rateRepository,
            addFundsOptions: { [] },
            openStaking: {}
        )
    }

    func settledState(of sut: TokenDetailsEarnStateProvider) async throws -> TokenDetailsEarnStateProvider.State {
        try await firstState(of: sut) { state in
            if case .earn(.loading) = state {
                return false
            }

            return true
        }
    }

    func firstState(
        of sut: TokenDetailsEarnStateProvider,
        where predicate: @escaping (TokenDetailsEarnStateProvider.State) -> Bool
    ) async throws -> TokenDetailsEarnStateProvider.State {
        try await sut.statePublisher.first(where: predicate).async()
    }
}

private final class RateStub: LendingRateRepository {
    private let results: OSAllocatedUnfairLock<(pending: [Result<Decimal, Error>], refreshCalls: Int)>
    private let apySubject: CurrentValueSubject<Decimal?, Never>

    init(results: [Result<Decimal, Error>], loadedApy: Decimal? = nil) {
        self.results = OSAllocatedUnfairLock(initialState: (results, 0))
        apySubject = CurrentValueSubject(loadedApy)
    }

    var refreshCalls: Int {
        results.withLock { $0.refreshCalls }
    }

    var apy: Decimal? {
        apySubject.value
    }

    var apyPublisher: AnyPublisher<Decimal?, Never> {
        apySubject.eraseToAnyPublisher()
    }

    func loadApyIfNeeded() {}

    func refreshApy() async throws -> Decimal {
        let result = results.withLock { results in
            results.refreshCalls += 1
            return results.pending.count > 1 ? results.pending.removeFirst() : results.pending[0]
        }

        let apy = try result.get()
        apySubject.send(apy)
        return apy
    }
}

private struct RateError: Error {}

private struct ReaderStub: LendingModuleReader {
    let positions: PositionStub

    func yieldModule() async throws -> String? { nil }
    func upgradeStatus(yieldModule: String) async throws -> YieldModuleUpgradeStatus { .upgradeUnavailable(version: nil) }
    func tokenStatus(wrappedNative: String) async throws -> YieldSupplyStatus { throw RateError() }
    func liquidityProvider() -> YieldModuleLendingLiquidityProvider? { positions }
}

private final class PositionStub: YieldModuleLendingLiquidityProvider, Sendable {
    private let results: OSAllocatedUnfairLock<[Result<Decimal, Error>]>

    init(results: [Result<Decimal, Error>]) {
        self.results = OSAllocatedUnfairLock(initialState: results)
    }

    func wrappedNative() async throws -> String { "" }

    func nativePosition() async throws -> Decimal {
        try results.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }.get()
    }

    func availableToWithdraw(nativePosition: Decimal) async throws -> Decimal { nativePosition }
}
