//
//  PolymarketFastTradingViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemUI
@testable import Tangem

@Suite("Polymarket fast trading settings: what the This device section shows")
struct PolymarketFastTradingThisDeviceSectionTests {
    @Test(
        "This device's key shows as its row even when it needs a new authorization",
        arguments: zip(
            [Fixture.key(.local, status: .expired), Fixture.key(.local, status: .unknown("SUSPENDED"))],
            [PolymarketFastTradingDevice.State.expired(at: Fixture.validUntil), .error]
        )
    )
    func thisDeviceKeyShowsItsRow(_ key: PolymarketSessionKey, _ state: PolymarketFastTradingDevice.State) throws {
        try #require(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: [key], signers: nil)) == .reenable)

        let row = PolymarketFastTradingDevice(
            source: .sessionKey(address: key.address),
            name: Fixture.deviceName,
            owner: .thisDevice(authorization: .reenable),
            state: state
        )

        #expect(Fixture.section([key]) == .device(row))
    }

    @Test("An activation this app runs shows this device as activating, not as a change in progress")
    func activationInFlightShowsThisDevice() {
        let activating = PolymarketFastTradingDevice(
            source: .operationInFlight,
            name: Fixture.thisDeviceName,
            owner: .thisDevice(authorization: nil),
            state: .activating
        )

        #expect(Fixture.section([Fixture.key(.otherDevice)], operations: [.activation]) == .device(activating))
    }

    @Test(
        "Without a key of its own this device is offered the authorization its keys call for",
        arguments: zip(
            [[], [Fixture.key(.otherDevice)], [Fixture.key(.local, status: .revoked)], [Fixture.key(.previous)]],
            [PolymarketFastTradingAuthorization.enable, .enable, .enable, .replace(previous: Fixture.key(.previous), revokesPrevious: true)]
        )
    )
    func activationOffer(_ keys: [PolymarketSessionKey], _ authorization: PolymarketFastTradingAuthorization) {
        let signers = keys.map(PolymarketSessionSigner.matching)

        #expect(Fixture.section(keys, signers: signers) == .activationOffer)
        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: keys, signers: signers)) == authorization)
    }

    @Test(
        "This device's key that failed to activate shows the activation card with the authorization the assessment chooses",
        arguments: zip(
            [[PolymarketSessionSigner](), [.matching(Fixture.key(.local, status: .failed))]],
            [PolymarketFastTradingAuthorization.reenable, .repair]
        )
    )
    func failedKeyShowsTheActivationCard(_ signers: [PolymarketSessionSigner], _ authorization: PolymarketFastTradingAuthorization) {
        let keys = [Fixture.key(.local, status: .failed)]

        #expect(Fixture.section(keys, signers: signers) == .activationOffer)
        #expect(PolymarketFastTradingAuthorization(assessment: Fixture.assess(keys: keys, signers: signers)) == authorization)
    }

    @Test(
        "A change running or settling on another device replaces the offer with what it waits for",
        arguments: [
            ([Fixture.key(.otherDevice)], [PolymarketFastTradingOperation.toggle], PolymarketFastTradingStrings.changeInProgress),
            ([Fixture.key(.otherDevice)], [.revocation], PolymarketFastTradingStrings.changeInProgress),
            ([Fixture.key(.otherDevice, status: .revoking)], [], PolymarketFastTradingStrings.revocationPending),
        ]
    )
    func heldOfferIsExplained(_ keys: [PolymarketSessionKey], _ operations: [PolymarketFastTradingOperation], _ notice: String) {
        #expect(Fixture.section(keys, operations: operations) == .notice(notice))
    }

    @Test(
        "A key whose exchange list can't be read shows a failed read with a retry instead of a wait",
        arguments: [[Fixture.key(.previous)], [Fixture.key(.local, status: .failed)]]
    )
    func unreadableExchangeListIsAFailedRead(_ keys: [PolymarketSessionKey]) {
        #expect(Fixture.section(keys, signers: nil) == .exchangeUnreadable)
    }
}

@MainActor
@Suite("Polymarket fast trading settings: revoking a device or an unknown signer")
struct PolymarketFastTradingRevocationTests {
    @Test("A card wallet revokes a device without a confirmation")
    func cardWalletRevokesAtOnce() async {
        let (sut, service) = Self.makeSUT(signingButtonType: .requiredNFCInteraction)

        sut.handleViewAction(.device(.revoke, Self.otherDevice))
        await sut.$isProcessing.firstValue { !$0 }

        #expect(sut.revocation == nil)
        #expect(service.revoked == [Fixture.Owner.otherDevice.address])
    }

    @Test("A wallet without a card confirms the revocation of a device before it signs")
    func walletWithoutCardConfirmsRevocation() {
        let (sut, service) = Self.makeSUT(signingButtonType: .holdToConfirm)

        sut.handleViewAction(.device(.revoke, Self.otherDevice))

        #expect(sut.revocation == .init(address: Fixture.Owner.otherDevice.address, title: Fixture.deviceName, kind: .device))
        #expect(service.revoked.isEmpty)
    }

    @Test("A card wallet revokes an unknown signer without a confirmation, as it revokes a device")
    func cardWalletRevokesAnUnknownSignerAtOnce() async throws {
        let (sut, service) = Self.makeSUT(signingButtonType: .requiredNFCInteraction)
        let signer = try #require(sut.foreignSigners.first)

        sut.handleViewAction(.revokeForeignSigner(signer))
        await sut.$isProcessing.firstValue { !$0 }

        #expect(sut.revocation == nil)
        #expect(service.revoked == [Self.unknownSigner.address])
    }

    @Test("A wallet without a card confirms the revocation of an unknown signer before it signs")
    func walletWithoutCardConfirmsTheRevocationOfAnUnknownSigner() throws {
        let (sut, service) = Self.makeSUT(signingButtonType: .holdToConfirm)
        let signer = try #require(sut.foreignSigners.first)

        sut.handleViewAction(.revokeForeignSigner(signer))

        #expect(sut.revocation == .init(address: Self.unknownSigner.address, title: signer.title, kind: .foreignSigner))
        #expect(service.revoked.isEmpty)
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketFastTradingRevocationTests {
    static let otherDevice = PolymarketFastTradingDevice(
        source: .sessionKey(address: Fixture.Owner.otherDevice.address),
        name: Fixture.deviceName,
        owner: .otherDevice,
        state: .active(until: Fixture.validUntil),
        isListedOnExchange: true
    )

    static let unknownSigner = PolymarketSessionSigner(
        address: "0xf0e1000000000000000000000000000000000009",
        scopes: ["CLOB"],
        validUntil: Fixture.validUntil
    )

    static func makeSUT(signingButtonType: SigningActionButtonViewType) -> (sut: PolymarketFastTradingViewModel, service: PolymarketFastTradingServiceSpy) {
        let keys = [Fixture.key(.otherDevice)]
        let signers = keys.map(PolymarketSessionSigner.matching) + [unknownSigner]
        let service = PolymarketFastTradingServiceSpy(state: .loaded(Fixture.assess(keys: keys, signers: signers)))
        let sut = PolymarketFastTradingViewModel(
            service: service,
            signingButtonType: signingButtonType,
            thisDeviceName: Fixture.thisDeviceName,
            onClose: {}
        )

        return (sut, service)
    }
}

private extension PolymarketSessionKeyFixtures {
    static func section(
        _ keys: [PolymarketSessionKey],
        signers: [PolymarketSessionSigner]? = nil,
        operations: [PolymarketFastTradingOperation] = []
    ) -> PolymarketFastTradingViewModel.ThisDeviceSection {
        PolymarketFastTradingViewModel.ThisDeviceSection(
            state: .loaded(assess(keys: keys, signers: signers, operations: operations)),
            thisDeviceName: thisDeviceName
        )
    }
}
