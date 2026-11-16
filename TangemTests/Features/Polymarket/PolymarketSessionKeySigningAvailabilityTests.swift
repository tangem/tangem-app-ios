//
//  PolymarketSessionKeySigningAvailabilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket fast trading: whether an order can be signed with the session key")
struct PolymarketSessionKeySigningAvailabilityTests {
    @Test("This device's active, enabled key the exchange lists signs orders")
    func usableKeyIsAvailable() {
        let key = Fixture.key(.local)

        #expect(Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)])))
    }

    @Test("A paused key does not sign orders")
    func pausedKeyIsUnavailable() {
        let key = Fixture.key(.local, isEnabled: false)

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)])))
    }

    @Test("A key the exchange does not list does not sign orders", arguments: [[PolymarketSessionSigner]?]([[], nil]))
    func unlistedKeyIsUnavailable(_ signers: [PolymarketSessionSigner]?) {
        #expect(!Self.isAvailable(Fixture.assess(keys: [Fixture.key(.local)], signers: signers)))
    }

    @Test(
        "A key the exchange lists with other terms than exactly the CLOB scope and the key's expiry does not sign orders",
        arguments: [
            PolymarketSessionSigner(address: Fixture.localAddress, scopes: ["CLOB"], validUntil: nil),
            PolymarketSessionSigner(address: Fixture.localAddress, scopes: [], validUntil: Fixture.validUntil),
            PolymarketSessionSigner(address: Fixture.localAddress, scopes: ["ALL"], validUntil: Fixture.validUntil),
            PolymarketSessionSigner(address: Fixture.localAddress, scopes: ["CLOB", "ALL"], validUntil: Fixture.validUntil),
            PolymarketSessionSigner(address: Fixture.localAddress, scopes: ["CLOB"], validUntil: Fixture.validUntil.addingTimeInterval(1)),
        ]
    )
    func unusableSignerIsUnavailable(_ signer: PolymarketSessionSigner) {
        let key = Fixture.key(.local, authorizedAt: Fixture.now.addingTimeInterval(-60))

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [signer])))
    }

    @Test("A usable key stops signing orders the expiry margin before it runs out")
    func availabilityEndsAtTheExpiryMargin() {
        let key = Fixture.key(.local)
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: [key], signers: [.matching(key)]))

        let availableUntil = CommonPolymarketSessionKeySigningAvailability.availableUntil(in: state, at: Fixture.now, isRefused: { _ in false })

        #expect(availableUntil == Fixture.validUntil.addingTimeInterval(-PolymarketSessionKey.signingExpiryMargin))
    }

    @Test("A key about to expire does not sign orders")
    func expiringKeyIsUnavailable() {
        let key = Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(60))

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)])))
    }

    @Test("A key that is still changing does not sign orders", arguments: [PolymarketSessionKey.Status.pending, .revoking])
    func settlingKeyIsUnavailable(_ status: PolymarketSessionKey.Status) {
        let key = Fixture.key(.local, status: status)

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)])))
    }

    @Test("Another device's key never signs this device's orders")
    func otherDeviceKeyIsUnavailable() {
        let key = Fixture.key(.otherDevice)

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)])))
    }

    @Test("A device whose key material is gone does not sign orders")
    func missingLocalKeyIsUnavailable() {
        let key = Fixture.key(.local)

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)], localAddress: nil)))
    }

    @Test("A key the exchange refused an order for stays off orders until it changes")
    func refusedKeyIsUnavailable() {
        let key = Fixture.key(.local)
        let state = PolymarketFastTradingState.loaded(Fixture.assess(keys: [key], signers: [.matching(key)]))

        #expect(!CommonPolymarketSessionKeySigningAvailability.isAvailable(in: state, at: Fixture.now, isRefused: { $0 == key.address }))
    }

    @Test("Nothing is signed with the session key while an operation runs")
    func operationInFlightIsUnavailable() {
        let key = Fixture.key(.local)

        #expect(!Self.isAvailable(Fixture.assess(keys: [key], signers: [.matching(key)], operations: [.toggle])))
    }

    @Test("An unknown state never signs with the session key", arguments: [PolymarketFastTradingState.loading, .failed])
    func unknownStateIsUnavailable(_ state: PolymarketFastTradingState) {
        #expect(!Self.isAvailable(in: state))
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketSessionKeySigningAvailabilityTests {
    static func isAvailable(_ assessment: PolymarketFastTradingAssessment) -> Bool {
        isAvailable(in: .loaded(assessment))
    }

    static func isAvailable(in state: PolymarketFastTradingState) -> Bool {
        CommonPolymarketSessionKeySigningAvailability.isAvailable(in: state, at: Fixture.now, isRefused: { _ in false })
    }
}
