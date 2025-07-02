//
//  DerivationUtil.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk

public enum DerivationUtil {
    static func deriveKeys(
        entropy: Data,
        passphrase: String? = nil,
        derivationPath: String,
        curve: EllipticCurve
    ) throws -> ExtendedPublicKey {
        let derivationPath = try DerivationPath(rawPath: derivationPath)

        let publicKey: Data

        switch curve {
        case .secp256k1:
            fatalError("Implement for secp256k1")
        case .ed25519:
            fatalError("Implement for ed")
        case .ed25519_slip0010:
            fatalError("Implement for ed_slip")
        case .bls12381_G2_AUG:
            throw HotWalletError.derivationIsNotSupported
        default:
            throw HotWalletError.tangemSdk(.unsupportedCurve)
        }

        return ExtendedPublicKey(publicKey: publicKey, chainCode: Data())
    }

    public static func deriveKeys(
        entropy: Data,
        passphrase: String? = nil,
        derivationPath: String,
        masterKey: Data
    ) throws -> ExtendedPublicKey {
        guard let curve = curve(for: masterKey, entropy: entropy, passphrase: passphrase) else {
            throw HotWalletError.tangemSdk(.unsupportedCurve)
        }

        return try deriveKeys(entropy: entropy, passphrase: passphrase, derivationPath: derivationPath, curve: curve)
    }

    private static func curve(for masterKey: Data, entropy: Data, passphrase: String? = nil,) -> EllipticCurve? {
        let curves: [EllipticCurve] = [.secp256k1, .ed25519, .ed25519_slip0010]

        return try? curves
            .first { curve in
                try Self.masterKey(from: curve, entropy: entropy, passphrase: passphrase) == masterKey
            }
    }

    private static func masterKey(from curve: EllipticCurve, entropy: Data, passphrase: String? = nil) throws -> Data {
        fatalError("Implement masterKey derivation for \(curve)")
    }
}
