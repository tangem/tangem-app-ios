//
//  PolymarketWalletOperationGateTests.swift
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

@Suite("Polymarket wallet operations: one relayer nonce at a time")
struct PolymarketWalletOperationGateTests {
    private static let wallet = UserWalletId(value: Data(repeating: 0x01, count: 32))
    private static let otherWallet = UserWalletId(value: Data(repeating: 0x02, count: 32))

    @Test("A second operation of the same wallet is refused while the first one holds the nonce")
    func secondOperationOfTheWalletIsRefused() async throws {
        let gate = PolymarketWalletOperationGate()

        _ = try await gate.exclusively(Self.wallet, orThrow: Busy.first) {
            await #expect(throws: Busy.second) {
                try await gate.exclusively(Self.wallet, orThrow: Busy.second) {}
            }
        }
    }

    @Test("Another wallet and the same wallet after the first operation ends are let through")
    func otherWalletAndLaterOperationsPass() async throws {
        let gate = PolymarketWalletOperationGate()

        try await gate.exclusively(Self.wallet, orThrow: Busy.first) {
            try await gate.exclusively(Self.otherWallet, orThrow: Busy.second) {}
        }

        try await gate.exclusively(Self.wallet, orThrow: Busy.second) {}
    }

    @Test("A failed operation frees the wallet")
    func failedOperationFreesTheWallet() async throws {
        let gate = PolymarketWalletOperationGate()

        await #expect(throws: Busy.first) {
            try await gate.exclusively(Self.wallet, orThrow: Busy.second) { throw Busy.first }
        }

        try await gate.exclusively(Self.wallet, orThrow: Busy.second) {}
    }

    @Test("A withdrawal or a claim is refused with its own error while a signed fast trading authorization kept for a resume still holds the next nonce")
    func slotRefusesWhileAKeptAuthorizationHoldsTheNonce() async throws {
        let (slot, _) = try Self.slot(keepingAuthorizationUntil: Self.start + 1, at: Self.start)
        var isRun = false

        await #expect(throws: Busy.pending) {
            try await slot.exclusively(orThrow: Busy.first, whileKeptAuthorizationPends: Busy.pending) { isRun = true }
        }

        #expect(!isRun)
    }

    @Test("A withdrawal or a claim started while the kept authorization is being sent again is refused with the pending error, not as already in progress")
    func slotRefusesWithThePendingErrorWhileTheResendHoldsTheWallet() async throws {
        let (slot, _) = try Self.slot(keepingAuthorizationUntil: Self.start + 1, at: Self.start)
        let entered = TestGate()
        let release = TestGate()
        let resend = Task {
            try await slot.gate.exclusively(Self.wallet, orThrow: Busy.second) {
                entered.open()
                await release.wait()
            }
        }

        await entered.wait()

        await #expect(throws: Busy.pending) {
            try await slot.exclusively(orThrow: Busy.first, whileKeptAuthorizationPends: Busy.pending) {}
        }

        release.open()
        try await resend.value
    }

    @Test("A withdrawal or a claim goes once the kept authorization can no longer run")
    func slotPassesAnExpiredKeptAuthorization() async throws {
        let (slot, _) = try Self.slot(keepingAuthorizationUntil: Self.start, at: Self.start)
        var isRun = false

        try await slot.exclusively(orThrow: Busy.first, whileKeptAuthorizationPends: Busy.pending) { isRun = true }

        #expect(isRun)
    }

    @Test("A withdrawal or a claim goes when the kept authorization can't be read, so a broken keychain never locks the funds")
    func slotPassesAnUnreadableKeptAuthorization() async throws {
        let (slot, storage) = try Self.slot(keepingAuthorizationUntil: Self.start + 1, at: Self.start)
        var isRun = false

        storage.readError = KeychainFailure()
        try await slot.exclusively(orThrow: Busy.first, whileKeptAuthorizationPends: Busy.pending) { isRun = true }

        #expect(isRun)
    }

    @Test("A withdrawal or a claim goes once the kept authorization went through and only the pause of its key is left")
    func slotPassesAnExecutedKeptAuthorization() async throws {
        let (slot, _) = try Self.slot(keepingAuthorizationUntil: Self.start + 1, at: Self.start, isExecuted: true)
        var isRun = false

        try await slot.exclusively(orThrow: Busy.first, whileKeptAuthorizationPends: Busy.pending) { isRun = true }

        #expect(isRun)
    }
}

// MARK: - Helpers

private extension PolymarketWalletOperationGateTests {
    static let start: TimeInterval = 1_789_430_400

    static func slot(
        keepingAuthorizationUntil deadline: TimeInterval,
        at now: TimeInterval,
        isExecuted: Bool = false
    ) throws -> (slot: PolymarketWalletOperationSlot, storage: PolymarketSecureStorageSpy) {
        let storage = PolymarketSecureStorageSpy()
        let store = CommonPolymarketInterruptedAuthorizationStore(secureStorage: storage)
        let call = PolymarketRelayedBatch.Call(target: "0x5e55000000000000000000000000000000000001", data: "0x")
        let batch = PolymarketRelayedBatch(
            ownerAddress: "0x0000000000000000000000000000000000000001",
            depositWalletAddress: "0xd000000000000000000000000000000000000001",
            nonce: "8",
            deadline: String(Int(deadline)),
            calls: [call],
            signature: "0xbatch"
        )

        try store.save(
            PolymarketInterruptedAuthorization(
                revokedAddress: call.target,
                revocation: batch,
                batch: batch,
                grant: PolymarketSessionKeyGrant(sessionKeyAddress: call.target, validUntil: Date(timeIntervalSince1970: deadline), call: call),
                deviceId: PolymarketSessionKeyFixtures.deviceId,
                keepsPaused: isExecuted,
                purpose: .renewal,
                isExecuted: isExecuted
            ),
            for: wallet
        )

        let slot = PolymarketWalletOperationSlot(
            userWalletId: wallet,
            gate: PolymarketWalletOperationGate(),
            interruptedAuthorizations: store,
            serverClock: PolymarketServerClock(deviceNow: { Date(timeIntervalSince1970: now) })
        )

        return (slot, storage)
    }
}

private struct KeychainFailure: Error {}

private enum Busy: Error {
    case first
    case second
    case pending
}
