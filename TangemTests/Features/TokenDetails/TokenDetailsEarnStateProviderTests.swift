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
        "A staking error keeps the staking card when the cache holds the user's stake",
        arguments: [
            StakingManagerState.loadingError("error", cached: Self.cachedStake),
            .unavailableInRegion(cached: Self.cachedStake),
        ]
    )
    func stakingErrorWithCachedStake(staking: StakingManagerState) async throws {
        let state = try await settledState(of: makeSUT(rates: [.success(Self.rate)], staking: staking))

        guard case .staking(let shown) = state else {
            Issue.record("Expected the staking state, got \(state)")
            return
        }

        #expect(shown == staking)
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
}

// MARK: - Helpers

private extension TokenDetailsEarnStateProviderTests {
    static let rate = Decimal(147) / 10_000
    static let cachedStake = CachedStakingManagerState(rewardType: .apy, apy: 0.03, stakeState: .staked(balance: 1), date: Date())

    func makeSUT(rates: [Result<Decimal, Error>], staking: StakingManagerState = .notEnabled) -> TokenDetailsEarnStateProvider {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stakingManagerStateMock = staking

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
            rateProvider: RateStub(results: rates),
            addFundsOptions: { [] }
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

private final class RateStub: LendingRateProvider, Sendable {
    private let results: OSAllocatedUnfairLock<[Result<Decimal, Error>]>

    init(results: [Result<Decimal, Error>]) {
        self.results = OSAllocatedUnfairLock(initialState: results)
    }

    func currentApy() async throws -> Decimal {
        try results.withLock { $0.count > 1 ? $0.removeFirst() : $0[0] }.get()
    }
}

private struct RateError: Error {}
