//
//  PolymarketInterruptedAuthorizationStoreTests.swift
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

@Suite("Polymarket kept fast trading authorization")
struct PolymarketInterruptedAuthorizationStoreTests {
    @Test("A kept authorization reads back from the keychain with the batches, grant and intent it was saved with")
    func keptAuthorizationReadsBack() throws {
        let sut = CommonPolymarketInterruptedAuthorizationStore(secureStorage: PolymarketSecureStorageSpy())

        try sut.save(Self.authorization, for: Self.wallet)
        let loaded = try #require(try sut.load(for: Self.wallet))

        #expect(loaded.revocation == Self.authorization.revocation)
        #expect(loaded.batch == Self.authorization.batch)
        #expect(loaded.isOf(Self.authorization.grant))
        #expect(loaded.keepsPaused)
        #expect(loaded.purpose == .renewal)
        #expect(loaded.isExecuted)
    }
}

// MARK: - Helpers

private extension PolymarketInterruptedAuthorizationStoreTests {
    static let wallet = UserWalletId(value: Data(repeating: 0x05, count: 32))

    static let authorization: PolymarketInterruptedAuthorization = {
        let call = PolymarketRelayedBatch.Call(target: PolymarketSessionKeyFixtures.localAddress, data: "0xa9059cbb")

        return PolymarketInterruptedAuthorization(
            revokedAddress: PolymarketSessionKeyFixtures.localAddress,
            revocation: batch(nonce: "7", signature: "0xrevocation", call: call),
            batch: batch(nonce: "8", signature: "0xauthorization", call: call),
            grant: PolymarketSessionKeyGrant(
                sessionKeyAddress: PolymarketSessionKeyFixtures.localAddress,
                validUntil: PolymarketSessionKeyFixtures.validUntil.addingTimeInterval(0.123),
                call: call
            ),
            deviceId: PolymarketSessionKeyFixtures.deviceId,
            keepsPaused: true,
            purpose: .renewal,
            isExecuted: true
        )
    }()

    static func batch(nonce: String, signature: String, call: PolymarketRelayedBatch.Call) -> PolymarketRelayedBatch {
        PolymarketRelayedBatch(
            ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress,
            depositWalletAddress: "0xd000000000000000000000000000000000000001",
            nonce: nonce,
            deadline: "1789431600",
            calls: [call],
            signature: signature
        )
    }
}
