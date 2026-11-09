//
//  PolymarketFundsArrivalTrackerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

@Suite("Polymarket funds arrival", .timeLimit(.minutes(1)))
@MainActor
struct PolymarketFundsArrivalTrackerTests {
    @Test("A withdrawal reads the balance more often without raising the banner")
    func withdrawalRaisesNoBanner() {
        let sut = makeSUT()

        sut.startAwaitingBalanceChange()

        #expect(!sut.isAwaitingFunds)
        #expect(sut.isBalanceChangeExpected)
    }

    @Test("A balance that moves closes the window, whichever way it moved")
    func aMovedBalanceClosesTheWindow() async {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)

        sut.startAwaitingFunds()
        balance.send(8)
        await drainMain()

        #expect(!sut.isAwaitingFunds)
        #expect(!sut.isBalanceChangeExpected)
    }

    @Test("A balance arriving for the first time is the baseline, not a change")
    func theFirstKnownBalanceIsOnlyTheBaseline() async {
        let balance = CurrentValueSubject<Decimal?, Never>(nil)
        let sut = makeSUT(balance: balance)

        sut.startAwaitingFunds()
        balance.send(0)
        await drainMain()

        #expect(sut.isAwaitingFunds)

        balance.send(8)
        await drainMain()

        #expect(!sut.isAwaitingFunds)
    }

    @Test("A deposit that landed before the wait started raises no banner")
    func aDepositLandedBeforeTheWaitRaisesNoBanner() {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)
        let dispatched = sut.currentBalance

        balance.send(60)
        sut.startAwaitingFunds(since: dispatched)

        #expect(!sut.isAwaitingFunds)
        #expect(!sut.isBalanceChangeExpected)
    }

    @Test("A deposit still on its way is awaited against the balance at dispatch")
    func aDepositOnItsWayIsAwaitedAgainstTheDispatchBalance() async {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)

        sut.startAwaitingFunds(since: sut.currentBalance)

        #expect(sut.isAwaitingFunds)

        balance.send(60)
        await drainMain()

        #expect(!sut.isAwaitingFunds)
    }

    @Test("A deposit that never lands is given up on")
    func anUnlandedDepositTimesOut() async throws {
        let sut = makeSUT(delayProvider: InstantPollDelayProvider())

        sut.startAwaitingFunds()

        await sut.windowClosed()

        #expect(!sut.isAwaitingFunds)
        #expect(!sut.isBalanceChangeExpected)
    }

    @Test("The deposit is settled once the funds land, not when the wait starts")
    func theDepositSettlesWhenFundsLand() async {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)
        var settlements = 0

        sut.startAwaitingFunds(since: sut.currentBalance) { settlements += 1 }

        #expect(settlements == 0)

        balance.send(60)
        await drainMain()

        #expect(settlements == 1)
    }

    @Test("A deposit that already landed is settled right away")
    func aLandedDepositSettlesRightAway() {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)
        let dispatched = sut.currentBalance
        var settlements = 0

        balance.send(60)
        sut.startAwaitingFunds(since: dispatched) { settlements += 1 }

        #expect(settlements == 1)
    }

    @Test("A deposit that never lands is still settled when the wait gives up")
    func anUnlandedDepositSettlesOnTimeout() async throws {
        let sut = makeSUT(delayProvider: InstantPollDelayProvider())
        var settlements = 0

        sut.startAwaitingFunds { settlements += 1 }

        await sut.windowClosed()

        #expect(settlements == 1)
    }

    @Test("A second deposit keeps the first one's settlement")
    func aSecondDepositKeepsTheFirstSettlement() async {
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let sut = makeSUT(balance: balance)
        var firstSettlements = 0
        var secondSettlements = 0

        sut.startAwaitingFunds(since: sut.currentBalance) { firstSettlements += 1 }
        sut.startAwaitingFunds(since: sut.currentBalance) { secondSettlements += 1 }
        balance.send(60)
        await drainMain()

        #expect(firstSettlements == 1)
        #expect(secondSettlements == 1)
    }

    @Test("Re-entering the wallet while its funds are awaited keeps the banner")
    func reenteringWhileAwaitingKeepsTheBanner() async {
        let registry = PolymarketFundsArrivalTrackerRegistry()
        let wallet = NSObject()
        let balance = CurrentValueSubject<Decimal?, Never>(10)

        registry
            .tracker(for: Self.userWalletId, owner: wallet, balancePublisher: balance.eraseToAnyPublisher())
            .startAwaitingFunds(since: 10)

        let reentered = registry.tracker(for: Self.userWalletId, owner: wallet, balancePublisher: Empty().eraseToAnyPublisher())

        #expect(reentered.isAwaitingFunds)

        balance.send(60)
        await drainMain()

        #expect(!reentered.isAwaitingFunds)
    }

    @Test("A wallet model rebuilt on unlock watches its own balance instead of the old one")
    func aRebuiltWalletModelGetsItsOwnTracker() async {
        let registry = PolymarketFundsArrivalTrackerRegistry()
        let wallet = NSObject()
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let awaiting = registry.tracker(for: Self.userWalletId, owner: wallet, balancePublisher: balance.eraseToAnyPublisher())

        awaiting.startAwaitingFunds(since: 10)

        let rebuiltWallet = NSObject()
        let rebuiltBalance = CurrentValueSubject<Decimal?, Never>(20)
        let rebuilt = registry.tracker(for: Self.userWalletId, owner: rebuiltWallet, balancePublisher: rebuiltBalance.eraseToAnyPublisher())

        rebuilt.startAwaitingFunds(since: 20)
        rebuiltBalance.send(70)
        await drainMain()

        #expect(!rebuilt.isAwaitingFunds)
        #expect(awaiting.isAwaitingFunds)

        balance.send(60)
        await drainMain()

        #expect(!awaiting.isAwaitingFunds)
    }

    @Test("Funds awaited for one wallet raise no banner for another")
    func anotherWalletRaisesNoBanner() async {
        let registry = PolymarketFundsArrivalTrackerRegistry()
        let wallet = NSObject()
        let balance = CurrentValueSubject<Decimal?, Never>(10)
        let awaiting = registry.tracker(for: Self.userWalletId, owner: wallet, balancePublisher: balance.eraseToAnyPublisher())

        awaiting.startAwaitingFunds(since: 10)

        let other = registry.tracker(
            for: UserWalletId(value: Data(repeating: 0xCD, count: 32)),
            owner: wallet,
            balancePublisher: Empty().eraseToAnyPublisher()
        )

        #expect(awaiting.isAwaitingFunds)
        #expect(!other.isAwaitingFunds)

        balance.send(60)
        await drainMain()
    }
}

// MARK: - Fixtures

private extension PolymarketFundsArrivalTrackerTests {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))

    func makeSUT(
        balance: CurrentValueSubject<Decimal?, Never> = CurrentValueSubject(10),
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) -> PolymarketFundsArrivalTracker {
        PolymarketFundsArrivalTracker(
            balancePublisher: balance.eraseToAnyPublisher(),
            delayProvider: delayProvider
        )
    }

    func drainMain() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

private extension PolymarketFundsArrivalTracker {
    @MainActor
    func windowClosed() async {
        await $isBalanceChangeExpected.firstValue { !$0 }
    }
}
