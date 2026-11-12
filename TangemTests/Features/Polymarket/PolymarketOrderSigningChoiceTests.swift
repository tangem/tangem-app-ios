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

        #expect(sut.method == .sessionKey)
        #expect(sut.decide(tapped: .sessionKey) == .sign(.sessionKey))
    }

    @Test("Without a usable session key the order waits for the card")
    func unusableKeySignsWithTheCard() {
        let (sut, _) = makeSUT(isAvailable: false)

        #expect(sut.method == .ownerKey)
    }

    @Test("A tap on the card button is signed by the owner key even if the session key turned usable since")
    func cardTapSignsWithTheOwnerKey() {
        let (sut, _) = makeSUT(isAvailable: true)

        #expect(sut.decide(tapped: .ownerKey) == .sign(.ownerKey))
    }

    @Test("A key lost after the button showed holds the tap and the button turns to the card")
    func lostKeyHoldsTheTap() {
        let (sut, availability) = makeSUT(isAvailable: true)

        availability.publish(false)

        #expect(sut.decide(tapped: .sessionKey) == .routeChanged)
        #expect(sut.method == .ownerKey)
    }

    @Test("Deciding a tap the session key can no longer sign neither switches the button nor shows a notice")
    func decidingChangesNothing() {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        availability.runOut()

        #expect(sut.decide(tapped: .sessionKey) == .routeChanged)
        #expect(sut.method == .sessionKey)
        #expect(notices.recorded.isEmpty)
    }

    @Test("A tap the session key could no longer sign turns the button to the card with a notice, and the button returns to the session key once it is usable again")
    func routeChangeReturnsToTheSessionKey() {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        availability.runOut()
        sut.switchToOwnerKey()

        #expect(sut.method == .ownerKey)
        #expect(notices.recorded == [PolymarketFastTradingStrings.sessionKeyUnavailableNotice])

        availability.publish(true)

        #expect(sut.method == .sessionKey)
        #expect(sut.decide(tapped: .sessionKey) == .sign(.sessionKey))
    }

    @Test("A declined session key keeps the order on the card even if it looks usable again")
    func declinedKeyStaysOnTheCard() {
        let (sut, availability) = makeSUT(isAvailable: true)

        sut.declineSessionKey()
        availability.publish(true)

        #expect(sut.method == .ownerKey)
        #expect(sut.decide(tapped: .sessionKey) == .routeChanged)
    }

    @Test("A key that runs out while the order is open switches the button to the card before the tap")
    func expiringKeySwitchesToTheCard() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(
            isAvailable: true,
            availableUntil: PolymarketSessionKeyFixtures.now.addingTimeInterval(60)
        )
        let delayProvider = HoldingDelayProviderSpy(holdThreshold: 0)
        let sut = PolymarketOrderSigningChoice(
            availability: availability,
            delayProvider: delayProvider,
            now: { PolymarketSessionKeyFixtures.now },
            showNotice: { _ in }
        )

        let wait = await delayProvider.parks.first { _ in true }
        availability.runOut()
        delayProvider.resumeParkedWaits()

        _ = await sut.$method.firstValue { $0 == .ownerKey }

        #expect(wait == 60)
    }

    @Test("Declining the session key tells the user why")
    func decliningTellsWhy() {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        sut.declineSessionKey()

        #expect(notices.recorded == [PolymarketFastTradingStrings.sessionKeyUnavailableNotice])
    }
}

// MARK: - Helpers

private extension PolymarketOrderSigningChoiceTests {
    func makeSUT(isAvailable: Bool) -> (sut: PolymarketOrderSigningChoice, availability: PolymarketSessionKeySigningAvailabilityStub) {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: isAvailable)

        return (PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in }), availability)
    }
}
