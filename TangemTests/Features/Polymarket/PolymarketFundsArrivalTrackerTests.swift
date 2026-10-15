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

@Suite("Polymarket funds arrival")
struct PolymarketFundsArrivalTrackerTests {
    @Test("A deposit raises the banner and reads the balance more often")
    func depositRaisesTheBanner() {
        let sut = makeSUT()

        sut.startAwaitingFunds()

        #expect(sut.isAwaitingFunds)
        #expect(sut.isBalanceChangeExpected)
    }

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

        try await sut.windowClosed()

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

        try await sut.windowClosed()

        #expect(settlements == 1)
    }
}

// MARK: - Fixtures

private extension PolymarketFundsArrivalTrackerTests {
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
    func windowClosed() async throws {
        _ = try await $isBalanceChangeExpected
            .filter { !$0 }
            .eraseToAnyPublisher()
            .async()
    }
}
