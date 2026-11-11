//
//  PolymarketFastTradingAssessment.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
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
    var isLocalKeyRefused: Bool
    let revokingSince: [String: Date]
    let keptPausedKeyAddress: String?

    init(
        sessionKeys: [PolymarketSessionKey],
        localKeyAddress: String?,
        deviceId: String,
        signers: [PolymarketSessionSigner]?,
        now: Date,
        operations: [PolymarketFastTradingOperation] = [],
        isLocalKeyRefused: Bool = false,
        revokingSince: [String: Date] = [:],
        keptPausedKeyAddress: String? = nil
    ) {
        let keptPausedKeyAddress = keptPausedKeyAddress?.lowercased()

        self.sessionKeys = sessionKeys.map { $0.withLowercasedAddress.keepingPaused(keptPausedKeyAddress) }
        self.keptPausedKeyAddress = keptPausedKeyAddress
        self.localKeyAddress = localKeyAddress?.lowercased()
        self.deviceId = deviceId
        self.signers = signers?.map(\.withLowercasedAddress)
        self.now = now
        self.operations = operations
        self.isLocalKeyRefused = isLocalKeyRefused
        self.revokingSince = Dictionary(revokingSince.map { ($0.key.lowercased(), $0.value) }, uniquingKeysWith: { min($0, $1) })
    }
}

enum PolymarketFastTradingOperation: Equatable {
    case activation
    case renewal
    case revocation
    case toggle

    var authorizesLocalKey: Bool {
        switch self {
        case .activation, .renewal:
            true
        case .revocation, .toggle:
            false
        }
    }
}

struct PolymarketFastTradingAssessment: Equatable {
    let status: Status
    let sessionKeys: [PolymarketSessionKey]
    let localKeyAddress: String?
    let localKey: PolymarketSessionKey?
    let otherDeviceKeys: [PolymarketSessionKey]
    let foreignSigners: [PolymarketSessionSigner]
    let signersBeingRevoked: [PolymarketSessionSigner]
    let missingOnExchange: Set<String>
    let mismatchedOnExchange: Set<String>
    let settlingKey: PolymarketSessionKey?
    let isRenewDue: Bool
    let operations: [PolymarketFastTradingOperation]
    let now: Date

    private let isLocalKeyRefused: Bool
    private let revokingSince: [String: Date]
    private let exchangeListing: ExchangeListing

    init(snapshot: PolymarketFastTradingSnapshot) {
        let exchangeListing = ExchangeListing(signers: snapshot.signers)
        let missingOnExchange = Self.missingOnExchange(snapshot, listing: exchangeListing)
        let mismatchedOnExchange = Self.mismatchedOnExchange(snapshot, listing: exchangeListing)
        let settlingKey = snapshot.sessionKeys.first { Self.isSettling($0, snapshot: snapshot) }
        let localKey = Self.localKey(in: snapshot)

        status = Self.status(
            snapshot,
            own: localKey,
            listing: exchangeListing,
            settlingKey: settlingKey,
            missingOnExchange: missingOnExchange,
            mismatchedOnExchange: mismatchedOnExchange
        )
        sessionKeys = snapshot.sessionKeys
        localKeyAddress = snapshot.localKeyAddress
        self.localKey = localKey
        otherDeviceKeys = Self.otherDeviceKeys(in: snapshot)
        foreignSigners = Self.unrecordedSigners(snapshot).filter { !Self.isBeingRevoked($0, snapshot: snapshot) }
        signersBeingRevoked = Self.unrecordedSigners(snapshot).filter { Self.isBeingRevoked($0, snapshot: snapshot) }
        self.missingOnExchange = missingOnExchange
        self.mismatchedOnExchange = mismatchedOnExchange
        self.settlingKey = settlingKey
        isRenewDue = status.activeOrPausedKey.map { Self.isRenewDue($0, now: snapshot.now) } ?? false
        operations = snapshot.operations
        now = snapshot.now
        isLocalKeyRefused = snapshot.isLocalKeyRefused
        revokingSince = snapshot.revokingSince
        self.exchangeListing = exchangeListing
    }

    var isOperationInFlight: Bool {
        !operations.isEmpty
    }

    var hasSettlingChange: Bool {
        settlingKey != nil
    }

    var needsFollowUpReads: Bool {
        hasSettlingChange
    }

    var isExchangeUnreadable: Bool {
        status.isExchangeUnreadable
    }

    var activeOrPausedLocalKey: PolymarketSessionKey? {
        status.activeOrPausedKey
    }

    var hasForeignSigners: Bool {
        !foreignSigners.isEmpty
    }

    func isUsableOnExchange(_ sessionKey: PolymarketSessionKey, at date: Date) -> Bool {
        exchangeListing.signer(for: sessionKey.address)?.isUsable(at: date) ?? false
    }

    func usableUntil(_ sessionKey: PolymarketSessionKey) -> Date? {
        guard let keyValidUntil = sessionKey.validUntil, let signerValidUntil = exchangeListing.signer(for: sessionKey.address)?.validUntil else {
            return nil
        }

        return min(keyValidUntil, signerValidUntil).addingTimeInterval(-PolymarketSessionKey.signingExpiryMargin)
    }

    func isOutOfSyncWithExchange(_ sessionKey: PolymarketSessionKey) -> Bool {
        missingOnExchange.contains(sessionKey.address)
            || mismatchedOnExchange.contains(sessionKey.address)
            || (isLocalKeyRefused && sessionKey.address == localKeyAddress)
    }

    func isSettling(_ sessionKey: PolymarketSessionKey) -> Bool {
        Self.isSettling(sessionKey, now: now, operations: operations, localKeyAddress: localKeyAddress, revokingSince: revokingSince)
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
        case exchangeUnreadable(PolymarketSessionKey)
        case waitingForSettlement(PolymarketSessionKey)
        case replace(previous: PolymarketSessionKey, revokesPrevious: Bool)

        var activeOrPausedKey: PolymarketSessionKey? {
            switch self {
            case .active(let sessionKey), .paused(let sessionKey):
                sessionKey
            default:
                nil
            }
        }

        var isExchangeUnreadable: Bool {
            if case .exchangeUnreadable = self {
                return true
            }

            return false
        }
    }
}

// MARK: - Decision table

private extension PolymarketFastTradingAssessment {
    static func localKey(in snapshot: PolymarketFastTradingSnapshot) -> PolymarketSessionKey? {
        snapshot.localKeyAddress.flatMap(snapshot.sessionKeys.decisiveRecord(of:))
    }

    static func otherDeviceKeys(in snapshot: PolymarketFastTradingSnapshot) -> [PolymarketSessionKey] {
        let others = snapshot.sessionKeys.filter { $0.address != snapshot.localKeyAddress }

        return others.uniqueProperties(\.address).compactMap(others.decisiveRecord(of:))
    }

    static func status(
        _ snapshot: PolymarketFastTradingSnapshot,
        own: PolymarketSessionKey?,
        listing: ExchangeListing,
        settlingKey: PolymarketSessionKey?,
        missingOnExchange: Set<String>,
        mismatchedOnExchange: Set<String>
    ) -> Status {
        let previous = snapshot.sessionKeys.first { sessionKey in
            sessionKey.deviceId == snapshot.deviceId
                && sessionKey.address != snapshot.localKeyAddress
                && sessionKey.status == .active
                && !isExpired(sessionKey, now: snapshot.now)
        }

        if let own {
            let isInSync = !missingOnExchange.contains(own.address)
                && !mismatchedOnExchange.contains(own.address)
                && !snapshot.isLocalKeyRefused

            switch own.status {
            case .pending where isSettling(own, snapshot: snapshot):
                return .enabling(own)
            case .revoking where isSettling(own, snapshot: snapshot):
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
                return .exchangeUnreadable(previous)
            }

            return .replace(previous: previous, revokesPrevious: !missingOnExchange.contains(previous.address))
        }

        guard let own else {
            return .offerEnable
        }

        switch own.status {
        case .active where mismatchedOnExchange.contains(own.address):
            return .repairByRenewal(own)
        case .active where snapshot.isLocalKeyRefused && !isExpired(own, now: snapshot.now):
            return repairIfListed(own, listing: listing)
        case .failed:
            return repairIfListed(own, listing: listing)
        default:
            return .reenable(own)
        }
    }

    static func repairIfListed(_ own: PolymarketSessionKey, listing: ExchangeListing) -> Status {
        guard let isListed = listing.lists(own.address) else {
            return .exchangeUnreadable(own)
        }

        return isListed ? .repairByRenewal(own) : .reenable(own)
    }

    static func isSettling(_ sessionKey: PolymarketSessionKey, snapshot: PolymarketFastTradingSnapshot) -> Bool {
        isSettling(
            sessionKey,
            now: snapshot.now,
            operations: snapshot.operations,
            localKeyAddress: snapshot.localKeyAddress,
            revokingSince: snapshot.revokingSince
        )
    }

    static func isSettling(
        _ sessionKey: PolymarketSessionKey,
        now: Date,
        operations: [PolymarketFastTradingOperation],
        localKeyAddress: String?,
        revokingSince: [String: Date]
    ) -> Bool {
        switch sessionKey.status {
        case .revoking:
            guard let since = revokingSince[sessionKey.address] else {
                return true
            }

            return now.timeIntervalSince(since) < PolymarketSessionKey.backendHoldWindow
        case .pending:
            if sessionKey.address == localKeyAddress, operations.contains(where: \.authorizesLocalKey) {
                return true
            }

            guard let createdAt = sessionKey.createdAt else {
                return false
            }

            return now.timeIntervalSince(createdAt) < PolymarketSessionKey.backendHoldWindow
        case .active, .revoked, .expired, .failed, .unknown:
            return false
        }
    }
}

// MARK: - Refusal

extension PolymarketFastTradingAssessment {
    static func confirmsLocalKey(after refusal: PolymarketOrderSigningRefusal, in snapshot: PolymarketFastTradingSnapshot) -> Bool {
        guard
            let routedOn = refusal.routedOn,
            let localKey = localKey(in: snapshot),
            localKey.status == .active,
            !isExpired(localKey, now: snapshot.now),
            let signer = ExchangeListing(signers: snapshot.signers).signer(for: localKey.address),
            signer.isUsable(at: snapshot.now),
            !hasOtherValidity(signer, than: localKey)
        else {
            return false
        }

        return !routedOn.record.hasSameTerms(as: localKey) || !routedOn.signer.hasSameTerms(as: signer)
    }
}

private extension PolymarketSessionKey {
    func hasSameTerms(as other: PolymarketSessionKey) -> Bool {
        status == other.status
            && isEnabled == other.isEnabled
            && Set(scopes.map { $0.uppercased() }) == Set(other.scopes.map { $0.uppercased() })
            && PolymarketFastTradingAssessment.isSameValidity(validUntil, other.validUntil)
    }
}

private extension PolymarketSessionSigner {
    func hasSameTerms(as other: PolymarketSessionSigner) -> Bool {
        Set(scopes.map { $0.uppercased() }) == Set(other.scopes.map { $0.uppercased() })
            && PolymarketFastTradingAssessment.isSameValidity(validUntil, other.validUntil)
    }
}

// MARK: - Expiry

extension PolymarketFastTradingAssessment {
    static func isRenewDue(_ sessionKey: PolymarketSessionKey, now: Date) -> Bool {
        guard let renewAfter = sessionKey.renewAfter else {
            return expiresSoon(sessionKey, now: now)
        }

        return now >= renewAfter
    }

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

            return !signer.hasTradingTerms || hasOtherValidity(signer, than: sessionKey)
        }

        return Set(mismatched.map(\.address))
    }

    static func unrecordedSigners(_ snapshot: PolymarketFastTradingSnapshot) -> [PolymarketSessionSigner] {
        let recorded = Set(snapshot.sessionKeys.filter(\.isOurs).map(\.address))
            .union(snapshot.localKeyAddress.map { [$0] } ?? [])

        return (snapshot.signers ?? []).filter { signer in
            !recorded.contains(signer.address) && !signer.isExpired(at: snapshot.now)
        }
    }

    static func isBeingRevoked(_ signer: PolymarketSessionSigner, snapshot: PolymarketFastTradingSnapshot) -> Bool {
        guard let revokingSince = snapshot.revokingSince[signer.address] else {
            return false
        }

        return snapshot.now.timeIntervalSince(revokingSince) < PolymarketSessionKey.backendHoldWindow
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

        return !isSameValidity(listedValidUntil, validUntil)
    }

    static func isSameValidity(_ validUntil: Date?, _ otherValidUntil: Date?) -> Bool {
        guard let validUntil, let otherValidUntil else {
            return validUntil == nil && otherValidUntil == nil
        }

        return abs(validUntil.timeIntervalSince(otherValidUntil)) <= PolymarketSessionKey.validityTolerance
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
        static let renewalWindowDays = 30
        static let secondsInDay: TimeInterval = 24 * 60 * 60
    }
}

// MARK: - Our signers

private extension PolymarketSessionKey {
    var isOurs: Bool {
        switch status {
        case .pending, .active, .revoking, .unknown:
            true
        case .revoked, .expired, .failed:
            false
        }
    }
}

// MARK: - Record selection

extension Sequence where Element == PolymarketSessionKey {
    func decisiveRecord(of address: String) -> PolymarketSessionKey? {
        filter { $0.address.caseInsensitiveCompare(address) == .orderedSame }
            .min { $0.status.recordRank < $1.status.recordRank }
    }
}

// MARK: - Record rank

private extension PolymarketSessionKey.Status {
    var recordRank: Int {
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

    var hasTradingTerms: Bool {
        hasTradingScope && validUntil != nil
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

// MARK: - Kept pause

private extension PolymarketSessionKey {
    func keepingPaused(_ keptPausedKeyAddress: String?) -> PolymarketSessionKey {
        guard address == keptPausedKeyAddress, status == .active, isEnabled else {
            return self
        }

        return PolymarketSessionKey(
            address: address,
            deviceId: deviceId,
            deviceName: deviceName,
            isEnabled: false,
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

// MARK: - Settling keys

extension PolymarketFastTradingAssessment {
    static func settlingKeys(in snapshot: PolymarketFastTradingSnapshot) -> [PolymarketSessionKey] {
        snapshot.sessionKeys.filter { isSettling($0, snapshot: snapshot) }
    }
}
