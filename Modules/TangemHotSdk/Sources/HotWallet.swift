//
//  HotWallet.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

public struct HotWallet: Codable {
    /// Wallet's public key.  For `secp256k1`, the key can be compressed or uncompressed. Use `Secp256k1Key` for any conversions.
    public let publicKey: Data
    /// Optional chain code for BIP32 derivation.
    let chainCode: Data?
    /// Elliptic curve used for all wallet key operations.
    let curve: EllipticCurve
    /// Derived keys according to `Config.defaultDerivationPaths`
    public var derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]
}
