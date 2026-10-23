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
        let states = makeStates(readiness: .ready(makeReadiness(depositAvailability: .available([target]))), balance: .loaded(10))

        #expect(states.addFunds == .available)
        #expect(states.withdraw == .available)
    }

    @Test("A prepared account with nothing to deposit greys out add funds alone, withdraw still follows the balance")
    func addFundsIsWithheldWithoutDepositTargets() {
        let states = makeStates(readiness: .ready(makeReadiness(depositAvailability: .unavailable)), balance: .loaded(10))

        #expect(states.addFunds == .unavailable)
        #expect(states.withdraw == .available)
    }

    @Test("A withdrawal still being processed blocks the next one, however healthy the balance")
    func pendingWithdrawalBlocksTheNextOne() {
        let states = makeStates(readiness: .ready(makeReadiness(depositAvailability: .available([target]))), balance: .loaded(10), isWithdrawalPending: true)

        #expect(states.withdraw == .unavailable(.withdrawalInProgress))
        #expect(states.addFunds == .available)
    }

    @Test("A pending withdrawal does not outrank an account that is unavailable or still loading")
    func pendingWithdrawalYieldsToAccountReadiness() {
        #expect(makeStates(readiness: .unavailable, balance: .loaded(10), isWithdrawalPending: true).withdraw == .unavailable(.accountUnavailable))
        #expect(makeStates(readiness: .loading, balance: .loaded(10), isWithdrawalPending: true).withdraw == .loading)
    }

    @Test("A zero balance has nothing to withdraw")
    func zeroBalanceCannotBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(0))

        #expect(states.withdraw == .unavailable(.emptyBalance))
    }

    @Test("A balance below the bridge minimum cannot be withdrawn, and the reason names the minimum")
    func balanceBelowMinimumCannotBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(1))

        #expect(states.withdraw == .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(2))))
    }

    @Test("The bridge minimum is compared in the account's token, not in dollars")
    func minimumIsConvertedToTokenBeforeTheComparison() {
        let states = PolymarketBalanceBlockActionStates(
            readiness: prepared,
            collateralBalance: .loaded(3),
            usdToToken: { $0 * 2 },
            isWithdrawalPending: false
        )

        #expect(states.withdraw == .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(4))))
    }

    @Test("A balance exactly at the minimum can be withdrawn")
    func balanceAtMinimumCanBeWithdrawn() {
        let states = makeStates(readiness: prepared, balance: .loaded(2))

        #expect(states.withdraw == .available)
    }

    @Test("Without a known minimum the withdrawal is withheld, whatever the balance says, while add funds follows the deposit")
    func unknownMinimumWithholdsWithdraw() {
        let states = makeStates(
            readiness: .ready(makeReadiness(depositAvailability: .available([target]), withdrawalAvailability: .unavailable)),
            balance: .loaded(10)
        )

        #expect(states.withdraw == .unavailable(.minimumUnknown))
        #expect(states.addFunds == .available)
    }

    @Test("While the balance reloads or fails, the cached figure decides")
    func cachedBalanceDecidesDuringReloadAndFailure() {
        let tooSmall = TokenBalanceType.Cached(balance: 1, date: Date())
        let enough = TokenBalanceType.Cached(balance: 5, date: Date())

        #expect(makeStates(readiness: prepared, balance: .loading(tooSmall)).withdraw == .unavailable(.tooSmallBalance(minimumFormatted: PolymarketOrderFormatter.money(2))))
        #expect(makeStates(readiness: prepared, balance: .failure(enough)).withdraw == .available)
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
        .ready(makeReadiness(depositAvailability: .available([target])))
    }

    func makeReadiness(
        depositAvailability: PolymarketAccountFundsInteractor.DepositAvailability,
        withdrawalAvailability: PolymarketAccountFundsInteractor.WithdrawalAvailability = .available(minimumUSD: 2)
    ) -> PolymarketAccountFundsInteractor.Readiness {
        PolymarketAccountFundsInteractor.Readiness(
            depositWalletAddress: "0x1111111111111111111111111111111111111111",
            depositAvailability: depositAvailability,
            withdrawalAvailability: withdrawalAvailability
        )
    }

    func makeStates(
        readiness: PolymarketAccountFundsInteractor.State,
        balance: TokenBalanceType,
        isWithdrawalPending: Bool = false
    ) -> PolymarketBalanceBlockActionStates {
        PolymarketBalanceBlockActionStates(
            readiness: readiness,
            collateralBalance: balance,
            usdToToken: { $0 },
            isWithdrawalPending: isWithdrawalPending
        )
    }
}
