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
        #expect(Fixture.section(keys, signers: keys.map(PolymarketSessionSigner.matching)) == .activationOffer(authorization))
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

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

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
