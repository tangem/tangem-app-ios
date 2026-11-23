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
    func usableKeySignsWithSessionKey() async {
        let (sut, _) = makeSUT(isAvailable: true)

        #expect(sut.method == .sessionKey)
        #expect(await sut.decide(tapped: .sessionKey) == .sign(.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)))
    }

    @Test("Without a usable session key the order waits for the card")
    func unusableKeySignsWithTheCard() {
        let (sut, _) = makeSUT(isAvailable: false)

        #expect(sut.method == .ownerKey)
    }

    @Test("A tap on the card button is signed by the owner key even if the session key turned usable since")
    func cardTapSignsWithTheOwnerKey() async {
        let (sut, _) = makeSUT(isAvailable: true)

        #expect(await sut.decide(tapped: .ownerKey) == .sign(.ownerKey))
    }

    @Test("A key lost after the button showed holds the tap and the button turns to the card")
    func lostKeyHoldsTheTap() async {
        let (sut, availability) = makeSUT(isAvailable: true)

        availability.publish(false)

        #expect(await sut.decide(tapped: .sessionKey) == .routeChanged)
        #expect(sut.method == .ownerKey)
    }

    @Test("Deciding a tap the session key can no longer sign neither switches the button nor shows a notice")
    func decidingChangesNothing() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        availability.runOut()

        #expect(await sut.decide(tapped: .sessionKey) == .routeChanged)
        #expect(sut.method == .sessionKey)
        #expect(notices.recorded.isEmpty)
    }

    @Test("A tap the session key could no longer sign turns the button to the card with a notice, and the button returns to the session key once it is usable again")
    func routeChangeReturnsToTheSessionKey() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        availability.runOut()
        sut.switchToOwnerKey()

        #expect(sut.method == .ownerKey)
        #expect(notices.recorded == [PolymarketFastTradingStrings.sessionKeyUnavailableNotice])

        availability.publish(true)

        #expect(sut.method == .sessionKey)
        #expect(await sut.decide(tapped: .sessionKey) == .sign(.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)))
    }

    @Test("A declined session key keeps the order on the card even if it looks usable again")
    func declinedKeyStaysOnTheCard() async {
        let (sut, availability) = makeSUT(isAvailable: true)

        sut.declineSessionKey()
        availability.publish(true)

        #expect(sut.method == .ownerKey)
        #expect(await sut.decide(tapped: .sessionKey) == .routeChanged)
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

    @Test(
        "A tap while the entry check still runs waits for that check instead of starting another",
        arguments: zip(
            [PolymarketOrderSigningRoute.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session), .ownerKey],
            [PolymarketOrderSigningChoice.Decision.sign(.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)), .routeChanged]
        )
    )
    func tapWaitsForTheEntryCheck(_ readiness: PolymarketOrderSigningRoute, _ decision: PolymarketOrderSigningChoice.Decision) async {
        let gate = TestGate()
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true, readiness: readiness, readinessGate: gate)
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })

        let tap = Task { await sut.decide(tapped: .sessionKey) }
        gate.open()

        #expect(await tap.value == decision)
        #expect(availability.readinessChecks == 1)
    }

    @Test("A session key the readiness check finds not ready turns the button to the card without a notice")
    func notReadyOnEntryTurnsTheButtonToTheCard() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true, readiness: .ownerKey)
        let notices = TestSignal<String>()
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { notices.send($0) })

        #expect(sut.method == .sessionKey)

        _ = await sut.$method.firstValue { $0 == .ownerKey }

        #expect(notices.recorded.isEmpty)
    }

    @Test("A key not ready when the order opens is checked again once it turns usable, and the button returns to the session key when that check finds it ready")
    func freshCheckReturnsTheButtonToTheSessionKey() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true, readiness: .ownerKey)
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })

        _ = await sut.$method.firstValue { $0 == .ownerKey }

        availability.publish(false)
        availability.readiness = .sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)
        availability.publish(true)

        _ = await sut.$method.firstValue { $0 == .sessionKey }

        #expect(availability.readinessChecks == 2)
    }

    @Test("A tap is decided by the latest readiness check, not by the one the order opened with")
    func tapUsesTheLatestCheck() async {
        let availability = PolymarketSessionKeySigningAvailabilityStub(isAvailable: true, readiness: .ownerKey)
        let sut = PolymarketOrderSigningChoice(availability: availability, showNotice: { _ in })

        _ = await sut.$method.firstValue { $0 == .ownerKey }

        availability.publish(false)
        availability.readiness = .sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)
        availability.publish(true)

        #expect(await sut.decide(tapped: .sessionKey) == .sign(.sessionKey(PolymarketSessionKeySigningAvailabilityStub.session)))
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
