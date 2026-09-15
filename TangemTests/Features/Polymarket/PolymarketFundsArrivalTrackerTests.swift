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
    /// The banner is the only thing telling the user the deposit is on its way.
    @Test("A deposit raises the banner and reads the balance more often")
    func depositRaisesTheBanner() {
        let sut = makeSUT()

        sut.startAwaitingFunds()

        #expect(sut.isAwaitingFunds)
        #expect(sut.isBalanceChangeExpected)
    }

    /// A withdrawal takes money away, so there is nothing to announce — only a balance about to drop.
    @Test("A withdrawal reads the balance more often without raising the banner")
    func withdrawalRaisesNoBanner() {
        let sut = makeSUT()

        sut.startAwaitingWithdrawal()

        #expect(!sut.isAwaitingFunds)
        #expect(sut.isBalanceChangeExpected)
    }

    /// The whole point of the window: notice that the money landed.
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

    /// A balance nobody has read yet is not a baseline, so its first arrival must not pass for a change.
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

    /// Nothing may hold the window open forever when the money never arrives.
    @Test("A deposit that never lands is given up on")
    func anUnlandedDepositTimesOut() async throws {
        let sut = makeSUT(delayProvider: InstantPollDelayProvider())

        sut.startAwaitingFunds()

        try await sut.windowClosed()

        #expect(!sut.isAwaitingFunds)
        #expect(!sut.isBalanceChangeExpected)
    }
}

// MARK: - Fixtures

private extension PolymarketFundsArrivalTrackerTests {
    /// The production delay keeps the timeout out of the way of every test but the one that is about it.
    func makeSUT(
        balance: CurrentValueSubject<Decimal?, Never> = CurrentValueSubject(10),
        delayProvider: PollDelayProvider = TaskSleepPollDelayProvider()
    ) -> PolymarketFundsArrivalTracker {
        PolymarketFundsArrivalTracker(
            balancePublisher: balance.eraseToAnyPublisher(),
            delayProvider: delayProvider
        )
    }

    /// The tracker reads the balance on the main queue, so anything already sent has been handled by the
    /// time work queued afterwards runs.
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
