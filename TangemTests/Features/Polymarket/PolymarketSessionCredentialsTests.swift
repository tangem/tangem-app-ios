//
//  PolymarketSessionCredentialsTests.swift
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

@Suite("Polymarket session credentials")
struct PolymarketSessionCredentialsTests {
    @Test("The session key proves itself to the CLOB under its own address and gets its own credentials")
    func derivesUnderTheSessionKey() async throws {
        let fixture = Fixture()

        let session = try await fixture.sut.credentials()
        let digest = PolymarketClobAuth.digest(ownerAddress: Fixture.sessionKeyAddress, timestamp: Fixture.timestamp)

        #expect(session == PolymarketSessionCredentials(sessionKeyAddress: Fixture.sessionKeyAddress, credentials: Fixture.sessionCredentials))
        #expect(fixture.clob.authHeaders == [
            PolymarketCLOBAuthHeaders(
                ownerAddress: Fixture.sessionKeyAddress,
                signature: PolymarketSessionKeyStoreSpy.signature(for: digest),
                timestamp: Fixture.timestamp,
                nonce: PolymarketClobAuth.nonce
            ),
        ])
        #expect(fixture.clob.createRequests == 0)
    }

    @Test("A session key the CLOB has never seen gets its credentials created")
    func createsWhenThereIsNothingToDerive() async throws {
        let fixture = Fixture(deriveResult: .failure(PolymarketAPIError.http(statusCode: 400, problemDetail: nil)))

        let session = try await fixture.sut.credentials()

        #expect(session.credentials == Fixture.sessionCredentials)
        #expect(fixture.clob.deriveRequests == 1)
        #expect(fixture.clob.createRequests == 1)
    }

    @Test("An outage, a timeout or throttling while deriving is reported instead of minting a second set of credentials", arguments: [503, 408, 429])
    func outageIsNotACreation(_ statusCode: Int) async {
        let fixture = Fixture(deriveResult: .failure(PolymarketAPIError.http(statusCode: statusCode, problemDetail: nil)))

        await #expect(throws: PolymarketAPIError.self) {
            try await fixture.sut.credentials()
        }

        #expect(fixture.clob.createRequests == 0)
    }

    @Test("A device without a session key gets no credentials and no key is created for them")
    func missingKeyIsNotCreated() async {
        let fixture = Fixture(heldAddress: nil)

        await #expect(throws: CommonPolymarketSessionKeyStore.KeyError.keyMissing) {
            try await fixture.sut.credentials()
        }

        #expect(fixture.keyStore.generatedKeys == 0)
        #expect(fixture.clob.authHeaders.isEmpty)
    }

    @Test("Credentials are derived once and reused while the session key stays the same")
    func credentialsAreCached() async throws {
        let fixture = Fixture()

        _ = try await fixture.sut.credentials()
        _ = try await fixture.sut.credentials()

        #expect(fixture.clob.deriveRequests == 1)
    }
}

// MARK: - Helpers

private final class Fixture {
    static let userWalletId = UserWalletId(value: Data(repeating: 0x01, count: 32))
    static let sessionKeyAddress = "0x5e55000000000000000000000000000000000001"
    static let timestamp = "1789430400"
    static let sessionCredentials = PolymarketL2Credentials(apiKey: "session-key", secret: "c2VjcmV0", passphrase: "phrase")

    let keyStore: PolymarketSessionKeyStoreSpy
    let clob: PolymarketCLOBServiceStub
    let sut: CommonPolymarketSessionCredentialsProvider

    init(
        deriveResult: Result<PolymarketL2Credentials, Error> = .success(Fixture.sessionCredentials),
        heldAddress: String? = Fixture.sessionKeyAddress
    ) {
        keyStore = PolymarketSessionKeyStoreSpy(heldAddress: heldAddress)
        clob = PolymarketCLOBServiceStub(deriveResult: deriveResult, createResult: .success(Self.sessionCredentials))
        sut = CommonPolymarketSessionCredentialsProvider(
            userWalletId: Self.userWalletId,
            keyStore: keyStore,
            clobService: clob,
            now: { Date(timeIntervalSince1970: 1_789_430_400) }
        )
    }
}
