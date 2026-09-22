//
//  UserWalletAttestation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data

/// Cryptographic proof that a user wallet belongs to the device registering it with the backend,
/// produced by ``UserWalletRegistrationSigner`` and submitted as part of `POST /mobile/wallet/register`.
///
/// Two independent claims, verified separately by the backend:
/// - `walletSignature` proves possession of the wallet's own private key.
/// - `cardSignature` additionally proves the key lives on a genuine, registered Tangem card.
public struct UserWalletAttestation: Equatable, Sendable {
    /// Proves possession of the wallet's own private key — signs `sha256(nonce ‖ salt)`.
    /// Always present, for both mobile and card-backed wallets.
    public let walletSignature: Signature

    /// Proves the wallet's key lives on a genuine, registered Tangem card.
    /// Signs `sha256(walletPublicKey ‖ nonce ‖ salt ‖ walletStatus)` with the card's own private key,
    /// which the backend verifies against its card registry.
    ///
    /// `nil` when either:
    /// - this is a mobile (software-only) wallet.
    /// - the card's firmware predates `COS 2.01` and can't produce a card signature at all. Such wallets are treated as `mobile`.
    public let cardSignature: Signature?

    /// The raw wallet status byte reported by the card (`Card.Wallet.Status.rawValue`).
    ///
    /// `nil` when either:
    /// - this is a mobile (software-only) wallet.
    /// - the card's firmware predates `COS 2.01` and can't produce a card signature at all. Such wallets are treated as `mobile`.
    /// - the card does produce a card signature (`COS 2.01+`) but predates `COS 6.16`,
    /// the minimum firmware that reports wallet status at all.
    public let walletStatus: Data?

    public init(walletSignature: Signature, cardSignature: Signature?, walletStatus: Data?) {
        self.walletSignature = walletSignature
        self.cardSignature = cardSignature
        self.walletStatus = walletStatus
    }
}

public extension UserWalletAttestation {
    /// A secp256k1 RSV signature (65 bytes: `R ‖ S ‖ V`) paired with the salt mixed into the hash it signs,
    /// as produced by `AttestWalletKeyTask`.
    struct Signature: Equatable, Sendable {
        /// The RSV signature bytes themselves.
        public let value: Data

        /// The salt mixed into the hash before signing.
        /// Required to reconstruct what was actually signed, so it's meaningless without ``value`` and vice versa.
        public let salt: Data

        public init(value: Data, salt: Data) {
            self.value = value
            self.salt = salt
        }
    }
}
