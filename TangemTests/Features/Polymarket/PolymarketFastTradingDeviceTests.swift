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
        "This device repairs its own key when a reactivation is offered, another device can be paused while live, and either revokes only while live or listed on the exchange",
        arguments: [
            (PolymarketFastTradingDevice.State.activating, true, PolymarketFastTradingDevice.Trailing.hidden, PolymarketFastTradingDevice.Trailing.hidden),
            (.revoking, true, .hidden, .hidden),
            (.activationFailed, true, .hidden, .button(.revoke)),
            (.activationFailed, false, .hidden, .hidden),
            (.active(until: Fixture.validUntil), false, .menu([.pause, .revoke]), .menu([.pause, .revoke])),
            (.paused(until: Fixture.validUntil), false, .menu([.resume, .revoke]), .menu([.resume, .revoke])),
            (.expired(at: Fixture.validUntil), true, .button(.reactivate), .button(.revoke)),
            (.expired(at: Fixture.validUntil), false, .button(.reactivate), .hidden),
            (.outOfSync, true, .menu([.reactivate, .revoke]), .button(.revoke)),
            (.outOfSync, false, .button(.reactivate), .hidden),
            (.error, true, .menu([.reactivate, .revoke]), .button(.revoke)),
            (.error, false, .button(.reactivate), .hidden),
        ]
    )
    func trailing(
        _ state: PolymarketFastTradingDevice.State,
        _ isListedOnExchange: Bool,
        _ thisDevice: PolymarketFastTradingDevice.Trailing,
        _ otherDevice: PolymarketFastTradingDevice.Trailing
    ) {
        let thisDeviceRow = Fixture.row(Fixture.key(), owner: .thisDevice(authorization: .reenable), state: state, isListedOnExchange: isListedOnExchange)
        let otherDeviceRow = Fixture.row(Fixture.key(), owner: .otherDevice, state: state, isListedOnExchange: isListedOnExchange)

        #expect(thisDeviceRow.trailing == thisDevice)
        #expect(otherDeviceRow.trailing == otherDevice)
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
        let row = Fixture.row(Fixture.key(), owner: .thisDevice(authorization: authorization), state: .expired(at: Fixture.validUntil))

        #expect(row.trailing == .button(action))
        #expect(action.title == authorization.title)
    }

    @Test("A paused key due for renewal offers the extension in its menu")
    func pausedKeyOffersExtension() {
        let devices = Fixture.devices([Fixture.key(.local, isEnabled: false, validUntil: Fixture.now.addingTimeInterval(12 * Fixture.day))])

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
        "This device's pending key shows as activating and is read again while the backend holds it pending, then its activation fails",
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
        _ expected: (state: PolymarketFastTradingDevice.State, isActivationFailed: Bool, isReadAgain: Bool)
    ) {
        let pending = Fixture.key(.local, status: .pending, authorizedAt: nil, createdAt: Fixture.now.addingTimeInterval(-pendingFor))
        let assessment = Fixture.assess(keys: [pending], signers: nil)

        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName)

        #expect(devices.map(\.state) == [expected.state])
        #expect(assessment.isLocalActivationFailed == expected.isActivationFailed)
        #expect(assessment.needsFollowUpReads == expected.isReadAgain)
    }

    @Test(
        "Another device's key still revoking after the backend stopped holding it shows an error and can be revoked again while the exchange lists it",
        arguments: zip([[PolymarketSessionSigner.matching(Fixture.key(.otherDevice, status: .revoking))], []], [true, false])
    )
    func stuckRevocationOfAnotherDeviceCanBeRevokedAgain(_ signers: [PolymarketSessionSigner], _ isRevocable: Bool) {
        let revoking = Fixture.key(.otherDevice, status: .revoking)
        let assessment = Fixture.assess(
            keys: [revoking],
            signers: signers,
            revokingSince: [revoking.address: Fixture.now.addingTimeInterval(-Fixture.batchExecutionWindow)]
        )

        let devices = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: Fixture.thisDeviceName)

        #expect(devices.map(\.state) == [.error])
        #expect(devices.map { $0.offers(.revoke) } == [isRevocable])
    }

    @Test(
        "Another device's expired key can be revoked only while the exchange lists it",
        arguments: zip([[PolymarketSessionSigner.matching(Fixture.key(.otherDevice, status: .expired))], [], nil] as [[PolymarketSessionSigner]?], [true, false, false])
    )
    func expiredKeyOfAnotherDeviceIsRevocableWhileListed(_ signers: [PolymarketSessionSigner]?, _ isRevocable: Bool) {
        let devices = Fixture.devices([Fixture.key(.otherDevice, status: .expired)], signers: signers)

        #expect(devices.map { $0.offers(.revoke) } == [isRevocable])
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

    @Test(
        "A key the exchange no longer lists needs a reconnect, one it lists with other terms stays active next to an unknown signer",
        arguments: zip(
            [
                [PolymarketSessionSigner](),
                [PolymarketSessionSigner(address: Fixture.Owner.otherDevice.address, scopes: ["CLOB"], validUntil: Fixture.validUntil.addingTimeInterval(Fixture.day))],
            ],
            [PolymarketFastTradingDevice.State.outOfSync, .active(until: Fixture.validUntil)]
        )
    )
    func keyMissingOnTheExchangeNeedsReconnect(_ signers: [PolymarketSessionSigner], _ state: PolymarketFastTradingDevice.State) {
        let devices = Fixture.devices([Fixture.key(.otherDevice)], signers: signers)

        #expect(devices.map(\.state) == [state])
    }

    @Test(
        "Every device expires soon from 30 days before its expiry on, and only this one offers to extend",
        arguments: zip([30 * Fixture.day, 30 * Fixture.day + 1], [true, false])
    )
    func expiresSoonInTheLastThirtyDays(_ validity: TimeInterval, _ expiresSoon: Bool) {
        let validUntil = Fixture.now.addingTimeInterval(validity)
        let local = Fixture.key(.local, validUntil: validUntil)
        let other = Fixture.key(.otherDevice, validUntil: validUntil)

        let devices = Fixture.devices([local, other])

        #expect(devices.map(\.expiresSoon) == [expiresSoon, expiresSoon])
        #expect(devices.map { $0.offers(.extend) } == [expiresSoon, false])
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
        state: PolymarketFastTradingDevice.State,
        isListedOnExchange: Bool = false
    ) -> PolymarketFastTradingDevice {
        PolymarketFastTradingDevice(
            source: .sessionKey(address: key.address),
            name: deviceName,
            owner: owner,
            state: state,
            isListedOnExchange: isListedOnExchange
        )
    }

    static func devices(
        _ keys: [PolymarketSessionKey],
        signers: [PolymarketSessionSigner]? = nil,
        operations: [PolymarketFastTradingOperation] = []
    ) -> [PolymarketFastTradingDevice] {
        PolymarketFastTradingDevice.devices(from: assess(keys: keys, signers: signers, operations: operations), thisDeviceName: thisDeviceName)
    }
}
