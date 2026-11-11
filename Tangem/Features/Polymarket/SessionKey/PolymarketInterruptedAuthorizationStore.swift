//
//  PolymarketInterruptedAuthorizationStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPolymarket
import TangemSdk

struct PolymarketInterruptedAuthorization: Codable, Sendable {
    var revokedAddress: String
    var revocation: PolymarketRelayedBatch
    var batch: PolymarketRelayedBatch
    var grant: PolymarketSessionKeyGrant
    var deviceId: String
    var keepsPaused: Bool
    var purpose: Purpose
    var isExecuted = false

    var executed: PolymarketInterruptedAuthorization {
        var copy = self
        copy.isExecuted = true
        return copy
    }

    func isExecutable(at date: Date) -> Bool {
        Self.runs(until: batch.deadline, at: date)
    }

    func holdsWalletNonce(at date: Date) -> Bool {
        !isExecuted && isExecutable(at: date)
    }

    func keepsPaused(sessionKeyAddress: String) -> Bool {
        keepsPaused && isFor(sessionKeyAddress: sessionKeyAddress)
    }

    func isFor(sessionKeyAddress: String) -> Bool {
        grant.sessionKeyAddress.caseInsensitiveCompare(sessionKeyAddress) == .orderedSame
    }

    func isOf(_ grant: PolymarketSessionKeyGrant) -> Bool {
        isFor(sessionKeyAddress: grant.sessionKeyAddress) && self.grant.call == grant.call
    }

    func isRevocationExecutable(at date: Date) -> Bool {
        Self.runs(until: revocation.deadline, at: date)
    }

    func stage(atWalletNonce walletNonce: String) -> NonceStage {
        guard let walletNonce = Int(walletNonce), let authorizationNonce = Int(batch.nonce) else {
            return .moved
        }

        switch walletNonce {
        case authorizationNonce:
            return .revocationExecuted
        case authorizationNonce - 1:
            return .revocationUnused
        default:
            return .moved
        }
    }

    static func isResumable(after error: Error) -> Bool {
        if PolymarketSessionKeyError.isCancellation(error) {
            return true
        }

        switch error {
        case PolymarketSessionKeyManagerError.unsettled:
            return true
        case let error as PolymarketSessionKeyError:
            return error.isRetryableWithTheSameRequest || error.isBusyRefusal
        case let error as PolymarketAPIError:
            return error.isRetryable
        default:
            return false
        }
    }

    private static func runs(until deadline: String, at date: Date) -> Bool {
        guard let deadline = TimeInterval(deadline) else {
            return false
        }

        return date.timeIntervalSince1970 < deadline
    }
}

protocol PolymarketInterruptedAuthorizationStore {
    func save(_ authorization: PolymarketInterruptedAuthorization, for userWalletId: UserWalletId) throws
    func load(for userWalletId: UserWalletId) throws -> PolymarketInterruptedAuthorization?
    func delete(for userWalletId: UserWalletId) throws
}

// MARK: - Nonce stage

extension PolymarketInterruptedAuthorization {
    enum NonceStage: Equatable {
        case revocationUnused
        case revocationExecuted
        case moved
    }
}

// MARK: - Purpose

extension PolymarketInterruptedAuthorization {
    enum Purpose: String, Codable, Sendable {
        case activation
        case renewal
    }
}

final class CommonPolymarketInterruptedAuthorizationStore {
    private let secureStorage: any PolymarketSecureStorage

    init(secureStorage: any PolymarketSecureStorage = SecureStorage()) {
        self.secureStorage = secureStorage
    }
}

// MARK: - PolymarketInterruptedAuthorizationStore protocol conformance

extension CommonPolymarketInterruptedAuthorizationStore: PolymarketInterruptedAuthorizationStore {
    func save(_ authorization: PolymarketInterruptedAuthorization, for userWalletId: UserWalletId) throws {
        let data = try JSONEncoder().encode(authorization)
        try secureStorage.store(data, forKey: account(for: userWalletId), overwrite: true)
    }

    func load(for userWalletId: UserWalletId) throws -> PolymarketInterruptedAuthorization? {
        guard let data = try secureStorage.get(account(for: userWalletId)) else {
            return nil
        }

        return try JSONDecoder().decode(PolymarketInterruptedAuthorization.self, from: data)
    }

    func delete(for userWalletId: UserWalletId) throws {
        try secureStorage.delete(account(for: userWalletId))
    }
}

// MARK: - Private implementation

private extension CommonPolymarketInterruptedAuthorizationStore {
    func account(for userWalletId: UserWalletId) -> String {
        Constants.accountPrefix + userWalletId.stringValue.lowercased()
    }

    enum Constants {
        static let accountPrefix = "polymarket_interrupted_authorization_"
    }
}
