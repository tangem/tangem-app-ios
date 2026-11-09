//
//  PolymarketOrderSigningChoiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@MainActor
@Suite("Polymarket fast trading: the signing decision on the order screen", .timeLimit(.minutes(1)))
struct PolymarketOrderSigningChoiceTests {
    @Test("A usable session key signs the order and the button skips the card")
    func usableKeySignsWithSessionKey() {
        let (sut, _) = makeSUT(isAvailable: true)

        #expect(sut.signsWithSessionKey)
        #expect(sut.signing(tappedWithSessionKey: true) == .sessionKey)
    }

    @Test("Without a usable session key the order waits for the card")
    func unusableKeySignsWithTheCard() {
        let (sut, _) = makeSUT(isAvailable: false)

        #expect(!sut.signsWithSessionKey)
    }

    @Test("A tap on the card button is signed by the owner key even if the session key turned usable since")
    func cardTapSignsWithTheOwnerKey() {
        let (sut, _) = makeSUT(isAvailable: true)

        #expect(sut.signing(tappedWithSessionKey: false) == .ownerKey)
    }

    @Test("A key lost after the button showed holds the tap and switches the button to the card")
    func lostKeyHoldsTheTap() {
        let (sut, availability) = makeSUT(isAvailable: true)

        availability.publish(false)

        #expect(sut.signing(tappedWithSessionKey: true) == nil)
        #expect(!sut.signsWithSessionKey)
    }

    @Test("A declined session key keeps the order on the card even if it looks usable again")
    func declinedKeyStaysOnTheCard() {
        let (sut, availability) = makeSUT(isAvailable: true)

        sut.declineSessionKey()
        availability.publish(true)

        #expect(!sut.signsWithSessionKey)
        #expect(sut.signing(tappedWithSessionKey: true) == nil)
    }
}

// MARK: - Helpers

private extension PolymarketOrderSigningChoiceTests {
    func makeSUT(isAvailable: Bool) -> (sut: PolymarketOrderSigningChoice, availability: PolymarketSessionKeySigningAvailabilityStub) {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: isAvailable)

        return (PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in }), availability)
    }
}
