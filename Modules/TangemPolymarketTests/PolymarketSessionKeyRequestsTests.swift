//
//  PolymarketSessionKeyRequestsTests.swift
//  TangemPolymarketTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Polymarket session key requests", .timeLimit(.minutes(1)))
struct PolymarketSessionKeyRequestsTests {
    @Test("An authorization accepts a signed batch that carries the grant's call among others")
    func authorizationAcceptsABatchCarryingTheGrant() throws {
        let grant = try Fixtures.makeGrant(sessionKeyAddress: Fixtures.sessionKey)
        let batch = Fixtures.makeBatch(calls: [Fixtures.unrelatedCall, grant.call])

        let authorization = try PolymarketSessionKeyAuthorization(
            batch: batch,
            grant: grant,
            deviceId: "device-1",
            deviceName: "iPhone 17 Pro"
        )

        #expect(authorization.grant == grant)
        #expect(authorization.batch == batch)
    }

    @Test("An authorization refuses a signed batch that authorizes another key than the grant's")
    func authorizationRefusesABatchGrantingAnotherKey() throws {
        let grant = try Fixtures.makeGrant(sessionKeyAddress: Fixtures.sessionKey)
        let otherGrant = try Fixtures.makeGrant(sessionKeyAddress: Fixtures.otherSessionKey)

        #expect(throws: PolymarketSessionKeyRequestError.callMissingFromBatch) {
            try PolymarketSessionKeyAuthorization(
                batch: Fixtures.makeBatch(calls: [otherGrant.call]),
                grant: grant,
                deviceId: "device-1",
                deviceName: "iPhone 17 Pro"
            )
        }
    }

    @Test("A revocation accepts a signed batch that revokes its key, whatever case the deposit wallet is written in")
    func revocationAcceptsABatchRevokingTheKey() throws {
        let call = try PolymarketSessionKeyCalls.revoke(
            sessionKeyAddress: Fixtures.sessionKey,
            depositWalletAddress: Fixtures.depositWallet.lowercased()
        )
        let batch = Fixtures.makeBatch(calls: [call])

        let revocation = try PolymarketSessionKeyRevocation(batch: batch, sessionKeyAddress: Fixtures.sessionKey)

        #expect(revocation.sessionKeyAddress == Fixtures.sessionKey)
        #expect(revocation.batch == batch)
    }

    @Test("A revocation refuses a signed batch that revokes another key")
    func revocationRefusesABatchRevokingAnotherKey() throws {
        let call = try PolymarketSessionKeyCalls.revoke(
            sessionKeyAddress: Fixtures.otherSessionKey,
            depositWalletAddress: Fixtures.depositWallet
        )

        #expect(throws: PolymarketSessionKeyRequestError.callMissingFromBatch) {
            try PolymarketSessionKeyRevocation(batch: Fixtures.makeBatch(calls: [call]), sessionKeyAddress: Fixtures.sessionKey)
        }
    }
}

// MARK: - Fixtures

private enum Fixtures {
    static let sessionKey = "0x5E55000000000000000000000000000000000001"
    static let otherSessionKey = "0x5E55000000000000000000000000000000000002"
    static let depositWallet = "0xDEF0000000000000000000000000000000000002"
    static let unrelatedCall = PolymarketRelayedBatch.Call(target: "0xc011a7e12a19f7b1f670d46f03b03f3342e82dfb", data: "0x095ea7b3")

    static func makeGrant(sessionKeyAddress: String) throws -> PolymarketSessionKeyGrant {
        try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: sessionKeyAddress,
            depositWalletAddress: depositWallet,
            now: Date(timeIntervalSince1970: 1_789_430_400)
        )
    }

    static func makeBatch(calls: [PolymarketRelayedBatch.Call]) -> PolymarketRelayedBatch {
        PolymarketRelayedBatch(
            ownerAddress: "0x0AAA000000000000000000000000000000000001",
            depositWalletAddress: depositWallet,
            nonce: "7",
            deadline: "1789430400",
            calls: calls,
            signature: "0x51"
        )
    }
}
