//
//  PolymarketFastTradingDevice.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemPolymarket
import TangemUI

struct PolymarketFastTradingDevice: Identifiable, Equatable {
    let source: Source
    let name: String
    let owner: Owner
    let state: State
    let expiresInDays: Int?

    var id: String {
        switch source {
        case .sessionKey(let address):
            address
        case .operationInFlight:
            Constants.inFlightDeviceId
        }
    }

    var isThisDevice: Bool {
        owner != .otherDevice
    }

    init(source: Source, name: String, owner: Owner, state: State, expiresInDays: Int? = nil) {
        self.source = source
        self.name = name
        self.owner = owner
        self.state = state
        self.expiresInDays = expiresInDays
    }

    init?(sessionKey: PolymarketSessionKey, owner: Owner, assessment: PolymarketFastTradingAssessment) {
        guard let state = Self.state(of: sessionKey, owner: owner, assessment: assessment) else {
            return nil
        }

        self.init(
            source: .sessionKey(address: sessionKey.address),
            name: sessionKey.deviceName ?? PolymarketFastTradingStrings.unknownDevice,
            owner: owner,
            state: state,
            expiresInDays: state.showsExpiry && PolymarketFastTradingAssessment.isRenewDue(sessionKey, now: assessment.now)
                ? PolymarketFastTradingAssessment.daysUntilExpiry(of: sessionKey, now: assessment.now)
                : nil
        )
    }

    private static func state(of sessionKey: PolymarketSessionKey, owner: Owner, assessment: PolymarketFastTradingAssessment) -> State? {
        if case .thisDevice = owner, let inFlight = State(operationsInFlight: assessment.operations) {
            return inFlight
        }

        return State(
            sessionKey: sessionKey,
            isOutOfSync: assessment.isOutOfSyncWithExchange(sessionKey),
            isSettling: assessment.isSettling(sessionKey),
            now: assessment.now
        )
    }
}

// MARK: - Source

extension PolymarketFastTradingDevice {
    enum Source: Equatable, Sendable {
        case sessionKey(address: String)
        case operationInFlight
    }
}

// MARK: - Assessment

extension PolymarketFastTradingDevice {
    static func devices(
        from assessment: PolymarketFastTradingAssessment,
        thisDeviceName: String
    ) -> [PolymarketFastTradingDevice] {
        let thisDevice = assessment.localKey.flatMap { sessionKey in
            PolymarketFastTradingDevice(
                sessionKey: sessionKey,
                owner: .thisDevice(authorization: PolymarketFastTradingAuthorization(assessment: assessment)),
                assessment: assessment
            )
        } ?? operationInFlight(in: assessment, thisDeviceName: thisDeviceName)

        let otherDevices = assessment.otherDeviceKeys.compactMap { sessionKey in
            PolymarketFastTradingDevice(sessionKey: sessionKey, owner: .otherDevice, assessment: assessment)
        }

        return (thisDevice.map { [$0] } ?? []) + otherDevices
    }

    private static func operationInFlight(
        in assessment: PolymarketFastTradingAssessment,
        thisDeviceName: String
    ) -> PolymarketFastTradingDevice? {
        State(operationsInFlight: assessment.operations).map { state in
            PolymarketFastTradingDevice(
                source: .operationInFlight,
                name: thisDeviceName,
                owner: .thisDevice(authorization: nil),
                state: state
            )
        }
    }
}

// MARK: - Owner

extension PolymarketFastTradingDevice {
    enum Owner: Equatable {
        case thisDevice(authorization: PolymarketFastTradingAuthorization?)
        case otherDevice
    }
}

// MARK: - State

extension PolymarketFastTradingDevice {
    enum State: Equatable, Sendable {
        case activating
        case extending
        case activationFailed
        case active(until: Date)
        case paused(until: Date)
        case expired(at: Date?)
        case outOfSync
        case revoking
        case error

        init?(operationsInFlight operations: [PolymarketFastTradingOperation]) {
            switch operations.first(where: \.authorizesLocalKey) {
            case .renewal:
                self = .extending
            case .activation:
                self = .activating
            case .revocation, .toggle, nil:
                return nil
            }
        }

        init?(sessionKey: PolymarketSessionKey, isOutOfSync: Bool, isSettling: Bool, now: Date) {
            switch sessionKey.status {
            case .pending:
                self = isSettling ? .activating : .activationFailed
            case .revoking:
                self = isSettling ? .revoking : .error
            case .revoked:
                return nil
            case .failed:
                self = .activationFailed
            case .expired:
                self = .expired(at: sessionKey.validUntil)
            case .unknown:
                self = .error
            case .active:
                self = Self.liveState(of: sessionKey, isOutOfSync: isOutOfSync, now: now)
            }
        }

        var showsExpiry: Bool {
            switch self {
            case .active, .paused:
                true
            case .activating, .extending, .activationFailed, .expired, .outOfSync, .revoking, .error:
                false
            }
        }

        private static func liveState(of sessionKey: PolymarketSessionKey, isOutOfSync: Bool, now: Date) -> State {
            guard !PolymarketFastTradingAssessment.isExpired(sessionKey, now: now), let validUntil = sessionKey.validUntil else {
                return .expired(at: sessionKey.validUntil)
            }

            guard !isOutOfSync else {
                return .outOfSync
            }

            return sessionKey.isEnabled ? .active(until: validUntil) : .paused(until: validUntil)
        }
    }
}

// MARK: - Actions

extension PolymarketFastTradingDevice {
    enum Action: Hashable, Sendable {
        case activate
        case extend
        case pause
        case resume
        case reactivate
        case revoke

        var title: String {
            switch self {
            case .activate:
                Localization.commonActivate
            case .extend:
                PolymarketFastTradingStrings.extendFor180Days
            case .pause:
                PolymarketFastTradingStrings.pause
            case .resume:
                PolymarketFastTradingStrings.resume
            case .reactivate:
                PolymarketFastTradingStrings.reactivate
            case .revoke:
                PolymarketFastTradingStrings.revoke
            }
        }

        var isDestructive: Bool {
            self == .revoke
        }

        init(authorization: PolymarketFastTradingAuthorization) {
            switch authorization {
            case .renew:
                self = .extend
            case .enable, .replace:
                self = .activate
            case .reenable, .repair:
                self = .reactivate
            }
        }
    }

    enum Trailing: Equatable, Sendable {
        case hidden
        case menu([Action])
        case button(Action)
    }

    var trailing: Trailing {
        switch owner {
        case .thisDevice(let authorization):
            Self.thisDeviceTrailing(state: state, authorization: authorization)
        case .otherDevice:
            Self.otherDeviceTrailing(state: state)
        }
    }

    private static func thisDeviceTrailing(state: State, authorization: PolymarketFastTradingAuthorization?) -> Trailing {
        let offered = authorization.map(Action.init(authorization:))
        let extend: [Action] = offered == .extend ? [.extend] : []
        let activation = offered == .extend ? nil : offered

        switch state {
        case .activating, .extending, .revoking:
            return .hidden
        case .activationFailed, .expired:
            return activation.map(Trailing.button) ?? .hidden
        case .active:
            return .menu(extend + [.pause, .revoke])
        case .paused:
            return .menu(extend + [.resume, .revoke])
        case .outOfSync, .error:
            return activation.map { .menu([$0, .revoke]) } ?? .button(.revoke)
        }
    }

    private static func otherDeviceTrailing(state: State) -> Trailing {
        switch state {
        case .activating, .extending, .revoking, .activationFailed:
            .hidden
        case .active:
            .menu([.pause, .revoke])
        case .paused:
            .menu([.resume, .revoke])
        case .expired, .outOfSync, .error:
            .button(.revoke)
        }
    }
}

// MARK: - Appearance

extension PolymarketFastTradingDevice {
    enum Icon: Equatable {
        case spinner
        case glyph(ImageType, Avatar.IconAppearance)
    }

    var icon: Icon {
        switch state {
        case .activating, .extending, .revoking:
            .spinner
        case .activationFailed, .error:
            .glyph(DesignSystem.Icons.Error.regular20, .error)
        case .active:
            .glyph(DesignSystem.Icons.Checkmark.regular20, .success)
        case .paused:
            .glyph(DesignSystem.Icons.Snowflake.regular20, .info)
        case .expired, .outOfSync:
            .glyph(DesignSystem.Icons.Warning.regular20, .warning)
        }
    }

    var expiryBadge: String? {
        expiresInDays.map(PolymarketFastTradingStrings.expiresIn(days:))
    }

    var subtitle: String {
        let parts: [String?] = switch state {
        case .activating:
            [PolymarketFastTradingStrings.statusActivating]
        case .extending:
            [PolymarketFastTradingStrings.statusExtending]
        case .activationFailed:
            [PolymarketFastTradingStrings.statusActivationFailed]
        case .active(let until):
            [PolymarketFastTradingStrings.statusActive, PolymarketFastTradingStrings.until(Self.format(until))]
        case .paused(let until):
            [PolymarketFastTradingStrings.statusPaused, PolymarketFastTradingStrings.activeUntil(Self.format(until))]
        case .expired(let at):
            [PolymarketFastTradingStrings.statusExpired, at.map { PolymarketFastTradingStrings.expiredAt(Self.format($0)) }]
        case .outOfSync:
            [PolymarketFastTradingStrings.statusOutOfSync]
        case .revoking:
            [PolymarketFastTradingStrings.statusRevoking]
        case .error:
            [Localization.commonError]
        }

        return parts.compactMap { $0 }.joined(separator: " \(AppConstants.dotSign) ")
    }

    private static func format(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

// MARK: - Constants

private extension PolymarketFastTradingDevice {
    enum Constants {
        static let inFlightDeviceId = "this-device-in-flight"
    }
}
