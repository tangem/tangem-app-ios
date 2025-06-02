//
//  HotWallet.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

struct HotWallet {
    /// Wallet's public key.  For `secp256k1`, the key can be compressed or uncompressed. Use `Secp256k1Key` for any conversions.
    let publicKey: Data
    /// Optional chain code for BIP32 derivation.
    let chainCode: Data?
    /// Elliptic curve used for all wallet key operations.
    let curve: EllipticCurve
    /// Has this key been imported to a card. E.g. from seed phrase
    /// Derived keys according to `Config.defaultDerivationPaths`
    var derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]
}
