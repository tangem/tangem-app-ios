//
//  CollectiblesHotDelegateSigner.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import Foundation
import CryptoKit
public import TangemFoundation

public enum CollectiblesHotDelegateSignerError: Error, Equatable, Sendable {
    case keyMissing
    case invalidStoredKey
}

/// The key is a standalone ed25519 pair from device entropy, deliberately not seed-derived — its loss is
/// recovered by an `update_vault` re-key, not a backup.
public actor CollectiblesHotDelegateSigner {
    private let keyStore: any CollectiblesHotDelegateKeyStore
    private let userWalletId: UserWalletId

    public init(keyStore: any CollectiblesHotDelegateKeyStore, userWalletId: UserWalletId) {
        self.keyStore = keyStore
        self.userWalletId = userWalletId
    }

    /// Creates a fresh key, replacing whatever was held. Stored before the ceremony that names it on chain —
    /// a crash in between would otherwise strand a vault whose `hot_delegate` nobody holds.
    public func generateKey() throws -> Data {
        let key = Curve25519.Signing.PrivateKey()
        try keyStore.storePrivateKey(key.rawRepresentation, userWalletId: userWalletId)

        return key.publicKey.rawRepresentation
    }

    public func publicKey() throws -> Data? {
        guard let seed = try keyStore.privateKey(userWalletId: userWalletId) else {
            return nil
        }

        return try makeKey(seed: seed).publicKey.rawRepresentation
    }

    public func signSpin(_ message: Data) throws -> Data {
        try privateKey().signature(for: message)
    }
}

// MARK: - Private implementation

private extension CollectiblesHotDelegateSigner {
    func privateKey() throws -> Curve25519.Signing.PrivateKey {
        guard let seed = try keyStore.privateKey(userWalletId: userWalletId) else {
            throw CollectiblesHotDelegateSignerError.keyMissing
        }

        return try makeKey(seed: seed)
    }

    func makeKey(seed: Data) throws -> Curve25519.Signing.PrivateKey {
        do {
            return try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        } catch {
            throw CollectiblesHotDelegateSignerError.invalidStoredKey
        }
    }
}
