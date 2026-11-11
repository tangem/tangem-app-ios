//
//  PolymarketOnboardingFastTradingTests.swift
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

@MainActor
@Suite("Polymarket fast trading during onboarding", .timeLimit(.minutes(1)))
struct PolymarketOnboardingFastTradingTests {
    @Test("The authorization takes the nonce it is given and gives the card tap twenty minutes")
    func authorizationUsesTheGivenNonce() throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: Fixture.localAddress)
        let (sut, _, _) = makeSUT(keyStore: keyStore)

        let batch = try #require(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "7", followsApprovals: false))
        let expectedGrant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: Fixture.localAddress,
            depositWalletAddress: Self.depositWalletAddress,
            now: Fixture.now
        )
        let expectedBatch = PolymarketRelayedBatch.Unsigned(
            depositWalletAddress: Self.depositWalletAddress,
            nonce: "7",
            deadline: String(Int(Fixture.now.timeIntervalSince1970) + 1200),
            calls: [expectedGrant.call]
        )

        #expect(batch == expectedBatch)
        #expect(keyStore.generatedKeys == 0)
    }

    @Test("A device without a key gets one for the authorization")
    func missingKeyIsCreated() throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddress: nil)
        let (sut, _, _) = makeSUT(keyStore: keyStore)

        let batch = try #require(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "7", followsApprovals: false))
        let expectedGrant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: PolymarketSessionKeyStoreSpy.generatedAddress,
            depositWalletAddress: Self.depositWalletAddress,
            now: Fixture.now
        )

        #expect(batch.calls == [expectedGrant.call])
        #expect(keyStore.generatedKeys == 1)
    }

    @Test("A key store that can't be read keeps fast trading out of onboarding instead of replacing the key, and says so")
    func unreadableKeyStorePreparesNothing() async throws {
        let keyStore = PolymarketSessionKeyStoreSpy(heldAddresses: [.failure(PolymarketSessionKeyStoreSpy.ReadError())])
        let (sut, _, reports) = makeSUT(keyStore: keyStore)

        #expect(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "7", followsApprovals: false) == nil)
        #expect(keyStore.generatedKeys == 0)
        #expect(try await reports.next() == .notEnabled)
    }

    @Test("An authorization signed after the approvals takes the nonce right after theirs")
    func authorizationFollowsTheApprovals() throws {
        let (sut, _, _) = makeSUT()

        let batch = try #require(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "7", followsApprovals: true))

        #expect(batch.nonce == "8")
    }

    @Test("A relayer nonce that isn't a number keeps fast trading out of onboarding and says so")
    func unreadableNoncePreparesNothing() async throws {
        let (sut, _, reports) = makeSUT()

        #expect(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "next", followsApprovals: true) == nil)
        #expect(try await reports.next() == .notEnabled)
    }

    @Test("The signed authorization goes out once with the key and expiry it was prepared for")
    func submitsOnce() async throws {
        let (sut, authorize, _) = makeSUT()
        let unsigned = try #require(sut.makeAuthorization(depositWalletAddress: Self.depositWalletAddress, approvalsNonce: "7", followsApprovals: false))
        let signed = unsigned.signed(by: "0xowner", signature: "0xsigned")
        let expectedGrant = try PolymarketSessionKeyCalls.authorize(
            sessionKeyAddress: Fixture.localAddress,
            depositWalletAddress: Self.depositWalletAddress,
            now: Fixture.now
        )

        await sut.submit(signed)?.value
        await sut.submit(signed)?.value

        let calls = authorize.submitted.recorded
        let call = try #require(calls.first)

        #expect(calls.count == 1)
        #expect(call.batch == signed)
        #expect(call.grant == expectedGrant)
    }

    @Test("Nothing goes out for an authorization that was never prepared")
    func unpreparedSubmitIsIgnored() async throws {
        let (sut, authorize, _) = makeSUT()
        let unprepared = PolymarketRelayedBatch.Unsigned(depositWalletAddress: Self.depositWalletAddress, nonce: "8", deadline: "0", calls: [])

        let submission = sut.submit(unprepared.signed(by: "0xowner", signature: "0xsigned"))
        await submission?.value

        #expect(submission == nil)
        #expect(authorize.submitted.recorded.isEmpty)
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketOnboardingFastTradingTests {
    static let depositWalletAddress = "0xdef0000000000000000000000000000000000002"

    func makeSUT(
        keyStore: PolymarketSessionKeyStoreSpy = PolymarketSessionKeyStoreSpy(heldAddress: Fixture.localAddress)
    ) -> (sut: CommonPolymarketOnboardingFastTrading, authorize: AuthorizeSpy, reports: PolymarketTestSignal<PolymarketFastTradingFailure>) {
        let authorize = AuthorizeSpy()
        let reports = PolymarketTestSignal<PolymarketFastTradingFailure>()
        let sut = CommonPolymarketOnboardingFastTrading(
            authorizations: PolymarketSessionKeyAuthorizations(
                userWalletId: UserWalletId(value: Data(repeating: 0x04, count: 32)),
                keyStore: keyStore,
                serverClock: PolymarketServerClock(deviceNow: { Fixture.now })
            ),
            authorize: { batch, grant in
                authorize.record(.init(batch: batch, grant: grant))
            },
            report: { failure in
                reports.send(failure)
            }
        )

        return (sut, authorize, reports)
    }
}

// MARK: - Stubs

private final class AuthorizeSpy: Sendable {
    struct Call: Sendable {
        let batch: PolymarketRelayedBatch
        let grant: PolymarketSessionKeyGrant
    }

    let submitted = PolymarketTestSignal<Call>()

    func record(_ call: Call) {
        submitted.send(call)
    }
}
