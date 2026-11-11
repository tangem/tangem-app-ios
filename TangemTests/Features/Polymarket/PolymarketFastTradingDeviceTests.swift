//
//  PolymarketFastTradingDeviceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
@testable import Tangem

@Suite("Polymarket fast trading: session key status to device row")
struct PolymarketFastTradingDeviceStateTests {
    @Test(
        "A pending or revoking key shows its change in progress only while the backend holds it, then shows the change failed",
        arguments: [
            (PolymarketSessionKey.Status.pending, true, PolymarketFastTradingDevice.State.activating),
            (.pending, false, .activationFailed),
            (.revoking, true, .revoking),
            (.revoking, false, .error),
        ]
    )
    func changeShowsInProgressOnlyWhileHeld(_ status: PolymarketSessionKey.Status, _ isSettling: Bool, _ expected: PolymarketFastTradingDevice.State) {
        #expect(Fixture.state(Fixture.key(status: status), isSettling: isSettling) == expected)
    }

    @Test("An active key switched off is paused")
    func disabledKeyIsPaused() {
        #expect(Fixture.state(Fixture.key(isEnabled: false)) == .paused(until: Fixture.validUntil))
    }

    @Test(
        "An active key at or past its validity, or without one, is expired",
        arguments: [Fixture.now.addingTimeInterval(-1), Fixture.now, nil] as [Date?]
    )
    func activeKeyPastValidityIsExpired(_ validUntil: Date?) {
        #expect(Fixture.state(Fixture.key(validUntil: validUntil)) == .expired(at: validUntil))
    }

    @Test("An active key out of sync with the exchange needs a reconnect, even when paused", arguments: [true, false])
    func outOfSyncKeyNeedsReconnect(_ isEnabled: Bool) {
        #expect(Fixture.state(Fixture.key(isEnabled: isEnabled), isOutOfSync: true) == .outOfSync)
    }
}

@Suite("Polymarket fast trading: what a device row offers")
struct PolymarketFastTradingDeviceTrailingTests {
    @Test(
        "This device repairs its own key when a reactivation is offered, another device can only be paused or revoked",
        arguments: [
            (PolymarketFastTradingDevice.State.activating, PolymarketFastTradingDevice.Trailing.hidden, PolymarketFastTradingDevice.Trailing.hidden),
            (.revoking, .hidden, .hidden),
            (.activationFailed, .button(.reactivate), .hidden),
            (.active(until: Fixture.validUntil), .menu([.pause, .revoke]), .menu([.pause, .revoke])),
            (.paused(until: Fixture.validUntil), .menu([.resume, .revoke]), .menu([.resume, .revoke])),
            (.expired(at: Fixture.validUntil), .button(.reactivate), .button(.revoke)),
            (.outOfSync, .menu([.reactivate, .revoke]), .button(.revoke)),
            (.error, .menu([.reactivate, .revoke]), .button(.revoke)),
        ]
    )
    func trailing(
        _ state: PolymarketFastTradingDevice.State,
        _ thisDevice: PolymarketFastTradingDevice.Trailing,
        _ otherDevice: PolymarketFastTradingDevice.Trailing
    ) {
        #expect(Fixture.row(Fixture.key(), owner: .thisDevice(authorization: .reenable), state: state).trailing == thisDevice)
        #expect(Fixture.row(Fixture.key(), owner: .otherDevice, state: state).trailing == otherDevice)
    }

    @Test(
        "This device's row offers only the authorization the activation screen would sign",
        arguments: [
            [Fixture.key(.local, status: .failed)],
            [
                Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day)),
                Fixture.key(.otherDevice, status: .pending, createdAt: Fixture.now.addingTimeInterval(-60)),
            ],
        ]
    )
    func thisDeviceOffersTheScreensAuthorization(_ keys: [PolymarketSessionKey]) throws {
        let assessment = Fixture.assess(keys: keys, signers: nil)
        let thisDevice = try #require(PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName).first)

        #expect(PolymarketFastTradingAuthorization(assessment: assessment) == nil)
        #expect(![PolymarketFastTradingDevice.Action.activate, .reactivate, .extend].contains(where: thisDevice.offers))
    }

    @Test(
        "This device's row names the activation it offers as the activation screen and the banner do",
        arguments: zip(
            [PolymarketFastTradingAuthorization.enable, .replace(previous: Fixture.key(.previous), revokesPrevious: true), .reenable, .repair],
            [PolymarketFastTradingDevice.Action.activate, .activate, .reactivate, .reactivate]
        )
    )
    func thisDeviceNamesItsActivation(_ authorization: PolymarketFastTradingAuthorization, _ action: PolymarketFastTradingDevice.Action) {
        let row = Fixture.row(Fixture.key(), owner: .thisDevice(authorization: authorization), state: .activationFailed)

        #expect(row.trailing == .button(action))
        #expect(action.title == authorization.title)
    }

    @Test("A paused key due for renewal offers the extension in its menu")
    func pausedKeyOffersExtension() {
        let devices = Fixture.devices([Fixture.key(.local, isEnabled: false, renewAfter: Fixture.now.addingTimeInterval(-1))])

        #expect(devices.map { $0.offers(.extend) } == [true])
    }
}

@Suite("Polymarket fast trading: settings list")
struct PolymarketFastTradingDeviceListTests {
    @Test("This device comes first and revoked keys are hidden")
    func thisDeviceFirst() {
        let other = Fixture.key(.otherDevice)
        let revoked = Fixture.key(.previous, status: .revoked)
        let local = Fixture.key(.local)

        let devices = Fixture.devices([other, revoked, local])

        #expect(devices == [
            Fixture.row(local, owner: .thisDevice(authorization: nil), state: .active(until: Fixture.validUntil)),
            Fixture.row(other, owner: .otherDevice, state: .active(until: Fixture.validUntil)),
        ])
    }

    @Test("Several records of another device's key make one row, built from the record that decides")
    func otherDeviceRowFollowsTheChosenRecord() {
        let expired = Fixture.key(.otherDevice, status: .expired)
        let active = Fixture.key(.otherDevice)

        let devices = Fixture.devices([expired, active])

        #expect(devices == [Fixture.row(active, owner: .otherDevice, state: .active(until: Fixture.validUntil))])
    }

    @Test("Another device's key left pending past the deadline of its signed batch shows its activation failed")
    func stalePendingKeyOfAnotherDeviceShowsFailedActivation() {
        let stale = Fixture.key(.otherDevice, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-Fixture.batchExecutionWindow))

        #expect(Fixture.devices([stale]).map(\.state) == [.activationFailed])
    }

    @Test(
        "This device's pending key shows as activating and is read again while the backend holds it pending, then fails with a reactivation",
        arguments: zip(
            [Fixture.batchExecutionWindow - 1, Fixture.batchExecutionWindow],
            [
                (PolymarketFastTradingDevice.State.activating, false, true),
                (.activationFailed, true, false),
            ]
        )
    )
    func pendingLocalKeyActivatesWhileTheBackendHoldsIt(
        _ pendingFor: TimeInterval,
        _ expected: (state: PolymarketFastTradingDevice.State, offersReactivation: Bool, isReadAgain: Bool)
    ) {
        let pending = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-pendingFor))
        let assessment = Fixture.assess(keys: [pending], signers: nil)

        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName)

        #expect(devices.map(\.state) == [expected.state])
        #expect(devices.map { $0.offers(.reactivate) } == [expected.offersReactivation])
        #expect(assessment.needsFollowUpReads == expected.isReadAgain)
    }

    @Test("Another device's key still revoking after the backend stopped holding it shows an error and can be revoked again")
    func stuckRevocationOfAnotherDeviceCanBeRevokedAgain() {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let assessment = Fixture.assess(
            keys: [revoking],
            revokingSince: [revoking.address: Fixture.now.addingTimeInterval(-Fixture.batchExecutionWindow)]
        )

        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName)

        #expect(devices.map(\.state) == [.error])
        #expect(devices.map { $0.offers(.revoke) } == [true])
    }

    @Test(
        "While this app extends the key, this device shows the extension, whatever its record goes through",
        arguments: [PolymarketSessionKey.Status.revoking, .revoked, .pending]
    )
    func renewalShowsExtension(_ status: PolymarketSessionKey.Status) {
        let devices = Fixture.devices([Fixture.key(.local, status: status)], operations: [.renewal])

        #expect(devices.map(\.state) == [.extending])
    }

    @Test("A key the exchange refused needs a reconnect instead of showing as active")
    func refusedKeyNeedsReconnect() {
        let key = Fixture.key(.local)
        let assessment = Fixture.assess(keys: [key], signers: [.matching(key)], isLocalKeyRefused: true)

        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName)

        #expect(devices.map(\.state) == [.outOfSync])
        #expect(devices.map { $0.offers(.reactivate) } == [true])
    }

    @Test("Of several records of this device's key the row shows the one the status is built from")
    func thisDeviceRowFollowsTheChosenRecord() {
        let expired = Fixture.key(.local, status: .expired)
        let active = Fixture.key(.local)

        let devices = Fixture.devices([expired, active])

        #expect(devices == [Fixture.row(active, owner: .thisDevice(authorization: nil), state: .active(until: Fixture.validUntil))])
    }

    @Test("A key the exchange no longer lists or lists with other terms needs a reconnect", arguments: [
        [PolymarketSessionSigner](),
        [PolymarketSessionSigner(address: Fixture.Owner.otherDevice.address, scopes: ["CLOB"], validUntil: Fixture.validUntil.addingTimeInterval(Fixture.day))],
    ])
    func keyOutOfSyncWithTheExchangeNeedsReconnect(_ signers: [PolymarketSessionSigner]) {
        let devices = Fixture.devices([Fixture.key(.otherDevice)], signers: signers)

        #expect(devices.map(\.state) == [.outOfSync])
    }

    @Test("Within 30 days of expiry every device shows how many days are left, only this one offers to extend")
    func expiryWithinThirtyDays() {
        let validUntil = Fixture.now.addingTimeInterval(12 * Fixture.day)
        let local = Fixture.key(.local, validUntil: validUntil)
        let other = Fixture.key(.otherDevice, validUntil: validUntil)

        let devices = Fixture.devices([local, other])

        #expect(devices.map(\.expiresInDays) == [12, 12])
        #expect(devices.map { $0.offers(.extend) } == [true, false])
    }

    @Test("A key further than 30 days from expiry shows no expiry and offers no extension")
    func noExpiryBeyondThirtyDays() {
        let devices = Fixture.devices([Fixture.key(.local, validUntil: Fixture.now.addingTimeInterval(31 * Fixture.day))])

        #expect(devices.map(\.expiresInDays) == [nil])
        #expect(devices.map { $0.offers(.extend) } == [false])
    }

    @Test("The backend's renewal date offers the extension before the last 30 days")
    func renewAfterOffersExtension() {
        let devices = Fixture.devices([Fixture.key(.local, renewAfter: Fixture.now.addingTimeInterval(-1))])

        #expect(devices.map { $0.offers(.extend) } == [true])
    }

    @Test(
        "Every device shows the days left from the backend's renewal date on, whether or not the key is in its last 30 days",
        arguments: zip(
            [(120 * Fixture.day, Fixture.now.addingTimeInterval(-1)), (12 * Fixture.day, Fixture.now.addingTimeInterval(1))],
            [120, nil] as [Int?]
        )
    )
    func expiryBadgeFollowsTheRenewalDate(_ key: (validity: TimeInterval, renewAfter: Date), _ daysLeft: Int?) {
        let validUntil = Fixture.now.addingTimeInterval(key.validity)
        let local = Fixture.key(.local, validUntil: validUntil, renewAfter: key.renewAfter)
        let other = Fixture.key(.otherDevice, validUntil: validUntil, renewAfter: key.renewAfter)

        let devices = Fixture.devices([local, other])

        #expect(devices.map(\.expiresInDays) == [daysLeft, daysLeft])
    }

    @Test("While this app activates the key, this device shows as activating before the backend lists it")
    func activationInFlightShowsThisDevice() {
        let other = Fixture.key(.otherDevice)

        let devices = Fixture.devices([other], operations: [.activation])

        #expect(devices == [
            PolymarketFastTradingDevice(source: .operationInFlight, name: Fixture.thisDeviceName, owner: .thisDevice(authorization: nil), state: .activating),
            Fixture.row(other, owner: .otherDevice, state: .active(until: Fixture.validUntil)),
        ])
    }
}

// MARK: - Helpers

private typealias Fixture = PolymarketSessionKeyFixtures

private extension PolymarketFastTradingDevice {
    func offers(_ action: Action) -> Bool {
        switch trailing {
        case .hidden:
            false
        case .button(let offered):
            offered == action
        case .menu(let offered):
            offered.contains(action)
        }
    }
}

private extension PolymarketSessionKeyFixtures {
    static func state(_ key: PolymarketSessionKey, isOutOfSync: Bool = false, isSettling: Bool = true) -> PolymarketFastTradingDevice.State? {
        PolymarketFastTradingDevice.State(sessionKey: key, isOutOfSync: isOutOfSync, isSettling: isSettling, now: now)
    }

    static func row(
        _ key: PolymarketSessionKey,
        owner: PolymarketFastTradingDevice.Owner,
        state: PolymarketFastTradingDevice.State
    ) -> PolymarketFastTradingDevice {
        PolymarketFastTradingDevice(source: .sessionKey(address: key.address), name: deviceName, owner: owner, state: state)
    }

    static func devices(
        _ keys: [PolymarketSessionKey],
        signers: [PolymarketSessionSigner]? = nil,
        operations: [PolymarketFastTradingOperation] = []
    ) -> [PolymarketFastTradingDevice] {
        PolymarketFastTradingDevice.devices(from: assess(keys: keys, signers: signers, operations: operations), thisDeviceName: thisDeviceName)
    }
}
