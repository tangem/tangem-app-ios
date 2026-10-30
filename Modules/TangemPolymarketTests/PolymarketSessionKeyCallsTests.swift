//
//  PolymarketSessionKeyCallsTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket session key calls", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyCallsTests {
    @Test("Authorizing a session key grants it for 180 days from the whole second and calls the deposit wallet with the key and that expiry")
    func authorizeGrant() throws {
        let grant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: Fixtures.sessionKey,
            depositWalletAddress: Fixtures.depositWallet,
            now: Date(timeIntervalSince1970: 1_789_430_400.75)
        )

        #expect(grant.sessionKeyAddress == "0x5e55000000000000000000000000000000000001")
        #expect(grant.validUntil == Date(timeIntervalSince1970: 1_804_982_400))
        #expect(grant.call.target == "0xdef0000000000000000000000000000000000002")
        #expect(grant.call.value == "0")
        #expect(grant.call.data == "0x24017fae"
            + "0000000000000000000000005e55000000000000000000000000000000000001"
            + "000000000000000000000000000000000000000000000000000000006b95d880")
    }

    @Test("Revoking a session key calls the deposit wallet with the key alone")
    func revokeCalldata() throws {
        let call = try PolymarketSessionKeyCalls.revoke(
            sessionKeyAddress: Fixtures.sessionKey,
            depositWalletAddress: Fixtures.depositWallet
        )

        #expect(call.target == "0xdef0000000000000000000000000000000000002")
        #expect(call.value == "0")
        #expect(call.data == "0xe63f952f" + "0000000000000000000000005e55000000000000000000000000000000000001")
    }

    @Test("A malformed session key is refused instead of being encoded", arguments: Fixtures.malformedAddresses)
    func malformedSessionKeyIsRefused(_ address: String) {
        #expect(throws: PolymarketSessionKeyCallsError.invalidAddress(address)) {
            try PolymarketSessionKeyCalls.revoke(sessionKeyAddress: address, depositWalletAddress: Fixtures.depositWallet)
        }
    }

    @Test("A malformed deposit wallet is refused instead of being called", arguments: Fixtures.malformedAddresses)
    func malformedDepositWalletIsRefused(_ address: String) {
        #expect(throws: PolymarketSessionKeyCallsError.invalidAddress(address)) {
            try PolymarketSessionKeyCalls.revoke(sessionKeyAddress: Fixtures.sessionKey, depositWalletAddress: address)
        }
    }

    @Test("A clock that puts the expiry before the Unix epoch is refused instead of being encoded")
    func expiryBeforeTheEpochIsRefused() {
        #expect(throws: PolymarketSessionKeyCallsError.invalidValidUntil(-1)) {
            try PolymarketSessionKeyCalls.authorize(
                sessionKeyAddress: Fixtures.sessionKey,
                depositWalletAddress: Fixtures.depositWallet,
                now: Date(timeIntervalSince1970: -15_552_001)
            )
        }
    }
}

// MARK: - Fixtures

private enum Fixtures {
    static let sessionKey = "0x5E55000000000000000000000000000000000001"
    static let depositWallet = "0xDEF0000000000000000000000000000000000002"

    static let malformedAddresses = [
        "",
        "5E55000000000000000000000000000000000001",
        "0x5E550000000000000000000000000000000001",
        "0x5E5500000000000000000000000000000000000100",
        "0x" + String(repeating: "z", count: 40),
    ]
}
