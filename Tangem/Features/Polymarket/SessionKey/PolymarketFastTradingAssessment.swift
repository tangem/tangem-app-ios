//
//  PolymarketFastTradingAssessment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

enum PolymarketFastTradingState: Equatable {
    case loading
    case loaded(PolymarketFastTradingAssessment)
    case failed
}

struct PolymarketFastTradingSnapshot {
    let sessionKeys: [PolymarketSessionKey]
    let localKeyAddress: String?
    let deviceId: String
    let signers: [PolymarketSessionSigner]?
    let now: Date
    var operations: [PolymarketFastTradingOperation]

    init(
        sessionKeys: [PolymarketSessionKey],
        localKeyAddress: String?,
        deviceId: String,
        signers: [PolymarketSessionSigner]?,
        now: Date,
        operations: [PolymarketFastTradingOperation] = []
    ) {
        self.sessionKeys = sessionKeys.map(\.withLowercasedAddress)
        self.localKeyAddress = localKeyAddress?.lowercased()
        self.deviceId = deviceId
        self.signers = signers?.map(\.withLowercasedAddress)
        self.now = now
        self.operations = operations
    }
}

enum PolymarketFastTradingOperation: Equatable {
    case activation
    case revocation
    case toggle
}

struct PolymarketFastTradingAssessment: Equatable {
    let status: Status
    let sessionKeys: [PolymarketSessionKey]
    let localKeyAddress: String?
    let foreignSigners: [PolymarketSessionSigner]
    let missingOnExchange: Set<String>
    let mismatchedOnExchange: Set<String>
    let settlingKey: PolymarketSessionKey?
    let isRenewDue: Bool
    let operations: [PolymarketFastTradingOperation]
    let now: Date

    private let exchangeListing: ExchangeListing

    init(snapshot: PolymarketFastTradingSnapshot) {
        let exchangeListing = ExchangeListing(signers: snapshot.signers)
        let missingOnExchange = Self.missingOnExchange(snapshot, listing: exchangeListing)
        let mismatchedOnExchange = Self.mismatchedOnExchange(snapshot, listing: exchangeListing)
        let settlingKey = snapshot.sessionKeys.first { Self.isSettling($0, snapshot: snapshot) }

        status = Self.status(
            snapshot,
            listing: exchangeListing,
            settlingKey: settlingKey,
            missingOnExchange: missingOnExchange,
            mismatchedOnExchange: mismatchedOnExchange
        )
        sessionKeys = snapshot.sessionKeys
        localKeyAddress = snapshot.localKeyAddress
        foreignSigners = Self.foreignSigners(snapshot)
        self.missingOnExchange = missingOnExchange
        self.mismatchedOnExchange = mismatchedOnExchange
        self.settlingKey = settlingKey
        isRenewDue = Self.isRenewDue(status: status, now: snapshot.now)
        operations = snapshot.operations
        now = snapshot.now
        self.exchangeListing = exchangeListing
    }

    var isOperationInFlight: Bool {
        !operations.isEmpty
    }

    var isActivating: Bool {
        operations.contains(.activation)
    }

    var hasSettlingChange: Bool {
        settlingKey != nil
    }

    var activeOrPausedLocalKey: PolymarketSessionKey? {
        switch status {
        case .active(let sessionKey), .paused(let sessionKey): sessionKey
        default: nil
        }
    }

    var hasForeignSigners: Bool {
        !foreignSigners.isEmpty
    }

    func isLocalKey(_ sessionKey: PolymarketSessionKey) -> Bool {
        sessionKey.address == localKeyAddress
    }

    func isListedOnExchange(_ sessionKey: PolymarketSessionKey) -> Bool {
        exchangeListing.lists(sessionKey.address) ?? false
    }

    func isOutOfSyncWithExchange(_ sessionKey: PolymarketSessionKey) -> Bool {
        missingOnExchange.contains(sessionKey.address) || mismatchedOnExchange.contains(sessionKey.address)
    }
}

// MARK: - Status

extension PolymarketFastTradingAssessment {
    enum Status: Equatable {
        case offerEnable
        case enabling(PolymarketSessionKey)
        case active(PolymarketSessionKey)
        case paused(PolymarketSessionKey)
        case revoking(PolymarketSessionKey)
        case reenable(PolymarketSessionKey)
        case repairByRenewal(PolymarketSessionKey)
        case awaitingExchangeListing(PolymarketSessionKey)
        case waitingForSettlement(PolymarketSessionKey)
        case replace(previous: PolymarketSessionKey, revokesPrevious: Bool)
    }
}

// MARK: - Decision table

private extension PolymarketFastTradingAssessment {
    static func status(
        _ snapshot: PolymarketFastTradingSnapshot,
        listing: ExchangeListing,
        settlingKey: PolymarketSessionKey?,
        missingOnExchange: Set<String>,
        mismatchedOnExchange: Set<String>
    ) -> Status {
        let own = snapshot.localKeyAddress.flatMap { address in
            snapshot.sessionKeys
                .filter { $0.address == address }
                .min { $0.status.localKeyRank < $1.status.localKeyRank }
        }
        let previous = snapshot.sessionKeys.first { sessionKey in
            sessionKey.deviceId == snapshot.deviceId
                && sessionKey.address != snapshot.localKeyAddress
                && sessionKey.status == .active
                && !isExpired(sessionKey, now: snapshot.now)
        }

        if let own {
            let isInSync = !missingOnExchange.contains(own.address) && !mismatchedOnExchange.contains(own.address)

            switch own.status {
            case .pending where isSettling(own, snapshot: snapshot):
                return .enabling(own)
            case .revoking:
                return .revoking(own)
            case .active where !isExpired(own, now: snapshot.now) && isInSync:
                return own.isEnabled ? .active(own) : .paused(own)
            default:
                break
            }
        }

        if let settlingKey {
            return .waitingForSettlement(settlingKey)
        }

        if let previous {
            guard listing.lists(previous.address) != nil else {
                return .awaitingExchangeListing(previous)
            }

            return .replace(previous: previous, revokesPrevious: !missingOnExchange.contains(previous.address))
        }

        if let own, own.status == .active {
            return mismatchedOnExchange.contains(own.address) ? .repairByRenewal(own) : .reenable(own)
        }

        if let own {
            guard own.status == .failed else {
                return .reenable(own)
            }

            guard let isListed = listing.lists(own.address) else {
                return .awaitingExchangeListing(own)
            }

            return isListed ? .repairByRenewal(own) : .reenable(own)
        }

        return .offerEnable
    }

    static func isRenewDue(status: Status, now: Date) -> Bool {
        guard case .active(let sessionKey) = status else {
            return false
        }

        guard let renewAfter = sessionKey.renewAfter else {
            return expiresSoon(sessionKey, now: now)
        }

        return now >= renewAfter
    }

    static func isSettling(_ sessionKey: PolymarketSessionKey, snapshot: PolymarketFastTradingSnapshot) -> Bool {
        switch sessionKey.status {
        case .revoking:
            return true
        case .pending:
            if snapshot.operations.contains(.activation), sessionKey.address == snapshot.localKeyAddress {
                return true
            }

            guard let createdAt = sessionKey.createdAt else { return false }

            return snapshot.now.timeIntervalSince(createdAt) < Constants.pendingTimeout
        case .active, .revoked, .expired, .failed, .unknown:
            return false
        }
    }
}

// MARK: - Expiry

extension PolymarketFastTradingAssessment {
    static func isExpired(_ sessionKey: PolymarketSessionKey, now: Date) -> Bool {
        guard let validUntil = sessionKey.validUntil else { return true }

        return now >= validUntil
    }

    static func daysUntilExpiry(of sessionKey: PolymarketSessionKey, now: Date) -> Int? {
        guard let validUntil = sessionKey.validUntil, validUntil > now else { return nil }

        return Int((validUntil.timeIntervalSince(now) / Constants.secondsInDay).rounded(.up))
    }

    static func expiresSoon(_ sessionKey: PolymarketSessionKey, now: Date) -> Bool {
        daysUntilExpiry(of: sessionKey, now: now).map { $0 <= Constants.renewalWindowDays } ?? false
    }
}

// MARK: - Reconciliation with the exchange

private extension PolymarketFastTradingAssessment {
    struct ExchangeListing: Equatable {
        private let signers: [String: PolymarketSessionSigner]?

        init(signers: [PolymarketSessionSigner]?) {
            self.signers = signers.map { signers in
                Dictionary(signers.map { ($0.address, $0) }, uniquingKeysWith: { first, _ in first })
            }
        }

        func lists(_ address: String) -> Bool? {
            signers.map { $0[address] != nil }
        }

        func signer(for address: String) -> PolymarketSessionSigner? {
            signers?[address]
        }
    }

    static func missingOnExchange(_ snapshot: PolymarketFastTradingSnapshot, listing: ExchangeListing) -> Set<String> {
        let missing = snapshot.sessionKeys.filter { sessionKey in
            isExpectedOnExchange(sessionKey, now: snapshot.now) && listing.lists(sessionKey.address) == false
        }

        return Set(missing.map(\.address))
    }

    static func mismatchedOnExchange(_ snapshot: PolymarketFastTradingSnapshot, listing: ExchangeListing) -> Set<String> {
        let mismatched = snapshot.sessionKeys.filter { sessionKey in
            guard isExpectedOnExchange(sessionKey, now: snapshot.now), let signer = listing.signer(for: sessionKey.address) else {
                return false
            }

            return !signer.hasTradingScope || hasOtherValidity(signer, than: sessionKey)
        }

        return Set(mismatched.map(\.address))
    }

    static func foreignSigners(_ snapshot: PolymarketFastTradingSnapshot) -> [PolymarketSessionSigner] {
        let recorded = Set(snapshot.sessionKeys.filter { !$0.status.isEnded }.map(\.address))
            .union(snapshot.localKeyAddress.map { [$0] } ?? [])

        return (snapshot.signers ?? []).filter { signer in
            !recorded.contains(signer.address) && !signer.isExpired(at: snapshot.now)
        }
    }

    static func isExpectedOnExchange(_ sessionKey: PolymarketSessionKey, now: Date) -> Bool {
        sessionKey.status == .active
            && !isExpired(sessionKey, now: now)
            && !isAwaitingReadiness(sessionKey, now: now)
    }

    static func hasOtherValidity(_ signer: PolymarketSessionSigner, than sessionKey: PolymarketSessionKey) -> Bool {
        guard let listedValidUntil = signer.validUntil, let validUntil = sessionKey.validUntil else {
            return false
        }

        return abs(listedValidUntil.timeIntervalSince(validUntil)) > Constants.validityTolerance
    }

    static func isAwaitingReadiness(_ sessionKey: PolymarketSessionKey, now: Date) -> Bool {
        guard let readySince = sessionKey.authorizedAt ?? sessionKey.createdAt else { return false }

        return now.timeIntervalSince(readySince) < Constants.readinessGrace
    }
}

// MARK: - Constants

private extension PolymarketFastTradingAssessment {
    enum Constants {
        static let readinessGrace: TimeInterval = 10 * 60
        static let pendingTimeout: TimeInterval = 10 * 60
        static let validityTolerance: TimeInterval = 60
        static let renewalWindowDays = 30
        static let secondsInDay: TimeInterval = 24 * 60 * 60
    }
}

// MARK: - Ended records

private extension PolymarketSessionKey.Status {
    var isEnded: Bool {
        switch self {
        case .revoked, .expired, .failed: true
        case .pending, .active, .revoking, .unknown: false
        }
    }
}

// MARK: - Local key record

private extension PolymarketSessionKey.Status {
    var localKeyRank: Int {
        switch self {
        case .active: 0
        case .pending: 1
        case .revoking: 2
        case .failed: 3
        case .unknown: 4
        case .expired: 5
        case .revoked: 6
        }
    }
}

// MARK: - Session signer terms

extension PolymarketSessionSigner {
    var hasTradingScope: Bool {
        scopes.contains { Self.tradingScopes.contains($0.uppercased()) }
    }

    private static let tradingScopes: Set<String> = ["CLOB", "ALL"]
}

private extension PolymarketSessionSigner {
    func isExpired(at date: Date) -> Bool {
        validUntil.map { $0 <= date } ?? false
    }
}

// MARK: - Address normalization

private extension PolymarketSessionKey {
    var withLowercasedAddress: PolymarketSessionKey {
        PolymarketSessionKey(
            address: address.lowercased(),
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: isEnabled,
            status: status,
            scopes: scopes,
            validUntil: validUntil,
            renewAfter: renewAfter,
            authorizedAt: authorizedAt,
            createdAt: createdAt
        )
    }
}

private extension PolymarketSessionSigner {
    var withLowercasedAddress: PolymarketSessionSigner {
        PolymarketSessionSigner(address: address.lowercased(), scopes: scopes, validUntil: validUntil)
    }
}
