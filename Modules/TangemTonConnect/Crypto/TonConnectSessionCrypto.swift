//
//  TonConnectSessionCrypto.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Sodium

/// X25519 keypair of the wallet side of one session (`spec/session.md`).
///
/// The secret key must be stored in the Keychain by the caller; it is the only thing that lets the
/// wallet read the dApp's messages and is discarded when the session ends.
public struct TonConnectSessionKeyPair: Equatable, Sendable {
    public let publicKey: Data
    public let secretKey: Data

    public init(publicKey: Data, secretKey: Data) throws {
        guard publicKey.count == TonConnectClientID.byteCount, secretKey.count == TonConnectClientID.byteCount else {
            throw TonConnectError.cryptoFailure
        }
        self.publicKey = publicKey
        self.secretKey = secretKey
    }

    public var clientID: TonConnectClientID {
        // Length is validated in `init`.
        try! TonConnectClientID(publicKey: publicKey)
    }
}

/// End-to-end encryption between dApp and wallet on top of the untrusted HTTP bridge.
///
/// Wire format of every bridge message: `nonce (24 bytes) ++ nacl.box(plaintext, nonce, peer_pk, own_sk)`.
public struct TonConnectSessionCrypto: Sendable {
    public static let nonceByteCount = 24

    public init() {}

    /// Generates a fresh keypair. One keypair per session; a new keypair means a new session.
    public func generateKeyPair() throws -> TonConnectSessionKeyPair {
        guard let keyPair = Sodium().box.keyPair() else {
            throw TonConnectError.cryptoFailure
        }
        return try TonConnectSessionKeyPair(publicKey: Data(keyPair.publicKey), secretKey: Data(keyPair.secretKey))
    }

    /// Encrypts `plaintext` for `recipient` and returns `nonce ++ ciphertext`. The nonce is 24 fresh
    /// random bytes drawn by libsodium for every call.
    public func encrypt(_ plaintext: Data, to recipient: TonConnectClientID, using keyPair: TonConnectSessionKeyPair) throws -> Data {
        guard let sealed: Bytes = Sodium().box.seal(
            message: Array(plaintext),
            recipientPublicKey: Array(recipient.publicKey),
            senderSecretKey: Array(keyPair.secretKey)
        ) else {
            throw TonConnectError.cryptoFailure
        }
        return Data(sealed)
    }

    /// Opens `nonce ++ ciphertext` sent by `sender`. Any failure (wrong key, truncation, tampering)
    /// throws and the message must be discarded, never interpreted as plaintext.
    public func decrypt(_ envelope: Data, from sender: TonConnectClientID, using keyPair: TonConnectSessionKeyPair) throws -> Data {
        guard envelope.count > Self.nonceByteCount else {
            throw TonConnectError.decryptionFailed
        }

        guard let opened = Sodium().box.open(
            nonceAndAuthenticatedCipherText: Array(envelope),
            senderPublicKey: Array(sender.publicKey),
            recipientSecretKey: Array(keyPair.secretKey)
        ) else {
            throw TonConnectError.decryptionFailed
        }
        return Data(opened)
    }
}
