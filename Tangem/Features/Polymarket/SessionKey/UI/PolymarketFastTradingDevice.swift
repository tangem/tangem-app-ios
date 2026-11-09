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
    let address: String?
    let name: String
    let owner: Owner
    let state: State
    let expiresInDays: Int?

    var id: String {
        address ?? Constants.activatingDeviceId
    }

    var isThisDevice: Bool {
        owner != .otherDevice
    }

    init(address: String?, name: String, owner: Owner, state: State, expiresInDays: Int? = nil) {
        self.address = address
        self.name = name
        self.owner = owner
        self.state = state
        self.expiresInDays = expiresInDays
    }

    init?(sessionKey: PolymarketSessionKey, owner: Owner, isOutOfSync: Bool, now: Date) {
        guard let state = State(sessionKey: sessionKey, isOutOfSync: isOutOfSync, now: now) else {
            return nil
        }

        self.init(
            address: sessionKey.address,
            name: sessionKey.deviceName ?? PolymarketFastTradingStrings.unknownDevice,
            owner: owner,
            state: state,
            expiresInDays: state.showsExpiry && PolymarketFastTradingAssessment.expiresSoon(sessionKey, now: now)
                ? PolymarketFastTradingAssessment.daysUntilExpiry(of: sessionKey, now: now)
                : nil
        )
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
                owner: .thisDevice(isRenewDue: assessment.isRenewDue),
                isOutOfSync: assessment.isOutOfSyncWithExchange(sessionKey),
                now: assessment.now
            )
        }
        let otherDevices = assessment.sessionKeys
            .filter { !assessment.isLocalKey($0) }
            .compactMap { sessionKey in
                PolymarketFastTradingDevice(
                    sessionKey: sessionKey,
                    owner: .otherDevice,
                    isOutOfSync: assessment.isOutOfSyncWithExchange(sessionKey),
                    now: assessment.now
                )
            }

        if let thisDevice {
            return [thisDevice] + otherDevices
        }

        guard assessment.isActivating else {
            return otherDevices
        }

        let activating = PolymarketFastTradingDevice(
            address: nil,
            name: thisDeviceName,
            owner: .thisDevice(isRenewDue: false),
            state: .activating
        )

        return [activating] + otherDevices
    }
}

// MARK: - Owner

extension PolymarketFastTradingDevice {
    enum Owner: Equatable, Sendable {
        case thisDevice(isRenewDue: Bool)
        case otherDevice
    }
}

// MARK: - State

extension PolymarketFastTradingDevice {
    enum State: Equatable, Sendable {
        case activating
        case activationFailed
        case active(until: Date)
        case paused(until: Date)
        case expired(at: Date?)
        case outOfSync
        case revoking
        case error

        init?(sessionKey: PolymarketSessionKey, isOutOfSync: Bool, now: Date) {
            switch sessionKey.status {
            case .pending:
                self = .activating
            case .revoking:
                self = .revoking
            case .revoked:
                return nil
            case .failed:
                self = .activationFailed
            case .expired:
                self = .expired(at: sessionKey.validUntil)
            case .unknown:
                self = .error
            case .active:
                guard !PolymarketFastTradingAssessment.isExpired(sessionKey, now: now), let validUntil = sessionKey.validUntil else {
                    self = .expired(at: sessionKey.validUntil)
                    return
                }

                if isOutOfSync {
                    self = .outOfSync
                } else if !sessionKey.isEnabled {
                    self = .paused(until: validUntil)
                } else {
                    self = .active(until: validUntil)
                }
            }
        }

        var showsExpiry: Bool {
            switch self {
            case .active, .paused:
                true
            case .activating, .activationFailed, .expired, .outOfSync, .revoking, .error:
                false
            }
        }
    }
}

// MARK: - Actions

extension PolymarketFastTradingDevice {
    enum Action: Hashable, Sendable {
        case extend
        case pause
        case resume
        case reactivate
        case revoke

        var title: String {
            switch self {
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
    }

    enum Trailing: Equatable, Sendable {
        case hidden
        case menu([Action])
        case button(Action)
    }

    var trailing: Trailing {
        switch state {
        case .activating, .revoking:
            .hidden
        case .activationFailed:
            isThisDevice ? .button(.reactivate) : .hidden
        case .active:
            .menu(owner == .thisDevice(isRenewDue: true) ? [.extend, .pause, .revoke] : [.pause, .revoke])
        case .paused:
            .menu([.resume, .revoke])
        case .expired:
            isThisDevice ? .button(.reactivate) : .button(.revoke)
        case .outOfSync, .error:
            isThisDevice ? .menu([.reactivate, .revoke]) : .button(.revoke)
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
        case .activating, .revoking:
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
        static let activatingDeviceId = "this-device-activation"
    }
}
