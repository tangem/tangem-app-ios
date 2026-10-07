//
//  PolymarketBalanceBlockActionStatesTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket balance block action buttons")
struct PolymarketBalanceBlockActionStatesTests {
    @Test("Until the account is prepared both buttons wait")
    func bothButtonsWaitWhileTheAccountIsPreparing() {
        let states = makeStates(readiness: .loading, balance: .loaded(10))

        #expect(states.addFunds == .loading)
        #expect(states.withdraw == .loading)
    }

    @Test("An unavailable account greys out both buttons, whatever the balance says")
    func unavailableAccountBlocksBothButtons() {
        let states = makeStates(readiness: .unavailable, balance: .loaded(10))

        #expect(states.addFunds == .unavailable)
        #expect(states.withdraw == .unavailable(.accountUnavailable))
    }

    @Test("A prepared account with something to deposit offers add funds")
    func addFundsIsOfferedWithDepositTargets() {
        let states = makeStates(readiness: .ready(makeReadiness(targets: [target])), balance: .loaded(10))

        #expect(states.addFunds == .available)
        #expect(states.withdraw == .available)
    }

    @Test("A prepared account with nothing to deposit greys out add funds alone, withdraw still follows the balance")
    func addFundsIsWithheldWithoutDepositTargets() {
        let states = makeStates(readiness: .ready(makeReadiness(targets: [])), balance: .loaded(10))

        #expect(states.addFunds == .unavailable)
        #expect(states.withdraw == .available)
    }

    @Test("A zero balance has nothing to withdraw")
    func zeroBalanceCannotBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(0))

        #expect(states.withdraw == .unavailable(.emptyBalance))
    }

    @Test("A balance below the bridge minimum cannot be withdrawn, and the reason names the minimum")
    func balanceBelowMinimumCannotBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(1), minimum: 2)

        #expect(states.withdraw == .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(2))))
    }

    @Test("A balance exactly at the minimum can be withdrawn")
    func balanceAtMinimumCanBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(2), minimum: 2)

        #expect(states.withdraw == .available)
    }

    @Test("Without a known minimum any positive balance can be withdrawn")
    func anyPositiveBalanceCanBeWithdrawnWithoutAMinimum() {
        let states = makeStates(readiness: prepared, balance: .loaded(Decimal(string: "0.000001")!), minimum: nil)

        #expect(states.withdraw == .available)
    }

    @Test("While the balance reloads or fails, the cached figure decides")
    func cachedBalanceDecidesDuringReloadAndFailure() {
        let tooSmall = TokenBalanceType.Cached(balance: 1, date: Date())
        let enough = TokenBalanceType.Cached(balance: 5, date: Date())

        #expect(makeStates(readiness: prepared, balance: .loading(tooSmall), minimum: 2).withdraw == .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(2))))
        #expect(makeStates(readiness: prepared, balance: .failure(enough), minimum: 2).withdraw == .available)
    }

    @Test("A first load without a cache keeps withdraw waiting")
    func firstLoadWithoutCacheKeepsWithdrawWaiting() {
        let states = makeStates(readiness: prepared, balance: .loading(nil))

        #expect(states.withdraw == .loading)
    }

    @Test("A failed load without a cache reports the balance as unavailable")
    func failedLoadWithoutCacheReportsBalanceUnavailable() {
        let states = makeStates(readiness: prepared, balance: .failure(nil))

        #expect(states.withdraw == .unavailable(.balanceUnavailable))
    }

    @Test("A balance that never started loading is unavailable as well")
    func balanceThatNeverLoadedIsUnavailable() {
        let states = makeStates(readiness: prepared, balance: .empty(.noData))

        #expect(states.withdraw == .unavailable(.balanceUnavailable))
    }
}

// MARK: - Fixtures

private extension PolymarketBalanceBlockActionStatesTests {
    var target: PolymarketAccountFundsInteractor.DepositTarget {
        PolymarketAccountFundsInteractor.DepositTarget(
            entry: PolymarketDepositAssetCatalog.usdcOnPolygon,
            tokenItem: PolymarketUtilities.usdcTokenItem,
            minCheckoutUSD: 2,
            fundingAddress: "0x2222222222222222222222222222222222222222"
        )
    }

    var prepared: PolymarketAccountFundsInteractor.State {
        .ready(makeReadiness(targets: [target]))
    }

    func makeReadiness(targets: [PolymarketAccountFundsInteractor.DepositTarget]) -> PolymarketAccountFundsInteractor.Readiness {
        PolymarketAccountFundsInteractor.Readiness(
            depositWalletAddress: "0x1111111111111111111111111111111111111111",
            depositTargets: targets,
            collateralMinCheckoutUSD: 2
        )
    }

    func makeStates(
        readiness: PolymarketAccountFundsInteractor.State,
        balance: TokenBalanceType,
        minimum: Decimal? = 2
    ) -> PolymarketBalanceBlockActionStates {
        PolymarketBalanceBlockActionStates(readiness: readiness, collateralBalance: balance, withdrawMinimum: minimum)
    }
}
