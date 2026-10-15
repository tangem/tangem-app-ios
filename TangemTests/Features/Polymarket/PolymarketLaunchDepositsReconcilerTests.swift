//
//  PolymarketLaunchDepositsReconcilerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket deposits scan on launch")
struct PolymarketLaunchDepositsReconcilerTests {
    @Test("The scan is asked for once per launch, however often the balance loads")
    func asksOncePerLaunch() async {
        let calls = OSAllocatedUnfairLock<[String]>(initialState: [])
        let sut = makeSUT(ledger: PolymarketLaunchLedger()) { address in calls.withLock { $0.append(address) } }

        await sut.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value
        let second = sut.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)

        #expect(second == nil)
        #expect(calls.withLock { $0.count } == 1)
    }

    @Test("The scan targets the deposit wallet derived from the owner")
    func targetsTheDepositWallet() async throws {
        let calls = OSAllocatedUnfairLock<[String]>(initialState: [])
        let sut = makeSUT(ledger: PolymarketLaunchLedger()) { address in calls.withLock { $0.append(address) } }

        await sut.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value

        let expected = try PolymarketDepositWalletDeriver.derive(ownerAddress: Self.ownerAddress)
        #expect(calls.withLock { $0 } == [expected])
    }

    @Test("A blocked region skips the scan")
    func blockedRegionSkips() async {
        let calls = OSAllocatedUnfairLock<Int>(initialState: 0)
        let sut = makeSUT(ledger: PolymarketLaunchLedger(), isRegionBlocked: true) { _ in calls.withLock { $0 += 1 } }

        await sut.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value

        #expect(calls.withLock { $0 } == 0)
    }

    @Test("Each wallet gets its own scan within one launch")
    func eachWalletOnce() async {
        let ledger = PolymarketLaunchLedger()
        let calls = OSAllocatedUnfairLock<Int>(initialState: 0)
        let first = makeSUT(walletKey: "first", ledger: ledger) { _ in calls.withLock { $0 += 1 } }
        let second = makeSUT(walletKey: "second", ledger: ledger) { _ in calls.withLock { $0 += 1 } }

        await first.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value
        await second.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value

        #expect(calls.withLock { $0 } == 2)
    }

    @Test("A refused scan does not break the launch")
    func refusedScanIsSwallowed() async {
        let sut = makeSUT(ledger: PolymarketLaunchLedger()) { _ in
            throw PolymarketAPIError.http(statusCode: 429, problemDetail: nil)
        }

        await sut.reconcileOncePerLaunch(ownerAddress: Self.ownerAddress)?.value
    }
}

// MARK: - Helpers

private extension PolymarketLaunchDepositsReconcilerTests {
    static let ownerAddress = "0x1111111111111111111111111111111111111111"

    func makeSUT(
        walletKey: String = "wallet",
        ledger: PolymarketLaunchLedger,
        isRegionBlocked: Bool = false,
        reconcile: @escaping PolymarketLaunchDepositsReconciler.Reconcile
    ) -> PolymarketLaunchDepositsReconciler {
        PolymarketLaunchDepositsReconciler(
            walletKey: walletKey,
            ledger: ledger,
            isRegionBlocked: { isRegionBlocked },
            reconcile: reconcile
        )
    }
}
