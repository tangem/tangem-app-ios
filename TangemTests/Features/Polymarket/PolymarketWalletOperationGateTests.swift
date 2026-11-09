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
}

private enum Busy: Error {
    case first
    case second
}
