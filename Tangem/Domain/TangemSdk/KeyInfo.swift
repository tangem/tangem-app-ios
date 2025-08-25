//
//  KeyInfo.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemHotSdk

/// Describing wallets created on card or hot wallet
struct KeyInfo: Codable {
    /// Wallet's public key.  For `secp256k1`, the key can be compressed or uncompressed. Use `Secp256k1Key` for any conversions.
    public let publicKey: Data
    /// Optional chain code for BIP32 derivation.
    public let chainCode: Data?
    /// Elliptic curve used for all wallet key operations.
    public let curve: EllipticCurve
    /// Has this key been imported to a card. E.g. from seed phrase
    public let isImported: Bool?
    /// Derived keys according to `Config.defaultDerivationPaths`
    public var derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]
}

extension KeyInfo: PublicKeyProvider {}

extension CardDTO.Wallet {
    var keyInfo: KeyInfo {
        KeyInfo(
            publicKey: publicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: isImported,
            derivedKeys: derivedKeys
        )
    }
}

extension HotWallet {
    var keyInfo: KeyInfo {
        KeyInfo(
            publicKey: publicKey,
            chainCode: chainCode,
            curve: curve,
            isImported: true,
            derivedKeys: derivedKeys
        )
    }
}
