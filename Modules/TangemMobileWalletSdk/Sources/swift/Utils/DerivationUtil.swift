//
//  DerivationUtil.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk
import TrezorCrypto

public enum DerivationUtil {
    public static func deriveKeys(
        entropy: Data,
        passphrase: String = "",
        derivationPath: DerivationPath?,
        masterKey: Data
    ) throws -> ExtendedPublicKey {
        guard let curve = curve(for: masterKey, entropy: entropy, passphrase: passphrase) else {
            throw MobileWalletError.tangemSdk(.unsupportedCurve)
        }

        return try deriveKeys(entropy: entropy, passphrase: passphrase, derivationPath: derivationPath, curve: curve)
    }

    static func deriveKeys(
        entropy: Data,
        passphrase: String = "",
        derivationPath: DerivationPath?,
        curve: EllipticCurve
    ) throws -> ExtendedPublicKey {
        switch curve {
        case .secp256k1, .ed25519_slip0010, .ed25519:
            let result = try publicKeyDefault(
                entropy: entropy,
                passphrase: passphrase,
                derivationPath: derivationPath,
                curve: curve
            )

            return result
        default:
            throw MobileWalletError.tangemSdk(.unsupportedCurve)
        }
    }

    static func curve(for masterKey: Data, entropy: Data, passphrase: String) -> EllipticCurve? {
        let curves: [EllipticCurve] = [.secp256k1, .ed25519, .ed25519_slip0010]

        let curve = curves
            .first { curve in
                guard let key = try? Self.masterKey(from: curve, entropy: entropy, passphrase: passphrase) else {
                    return false
                }
                return key == masterKey
            }

        if curve == nil, (try? BLSUtil.publicKey(entropy: entropy, passphrase: passphrase).publicKey) == masterKey {
            return .bls12381_G2_AUG
        }

        return curve
    }
}

private extension DerivationUtil {
    static func masterKey(from curve: EllipticCurve, entropy: Data, passphrase: String) throws -> Data {
        try publicKeyDefault(entropy: entropy, passphrase: passphrase, derivationPath: nil, curve: curve).publicKey
    }

    static func publicKeyDefault(
        entropy: Data,
        passphrase: String,
        derivationPath: DerivationPath?,
        curve: EllipticCurve
    ) throws -> ExtendedPublicKey {
        var node = try HDNodeUtil.makeHDNode(
            entropy: entropy,
            passphrase: passphrase,
            derivationPath: derivationPath,
            curve: curve
        )

        defer {
            withUnsafeMutablePointer(to: &node) {
                memzero($0, MemoryLayout<HDNode>.size)
            }
        }

        guard hdnode_fill_public_key(&node) == 0 else {
            throw MobileWalletError.failedToDeriveKey
        }

        let publicKey = try withUnsafeBytes(of: node.public_key) {
            let data = Data($0)
            switch curve {
            case .secp256k1:
                return data.suffix(Constants.secp256k1PublicKeySize)
            case .ed25519, .ed25519_slip0010:
                return data.suffix(Constants.edPublicKeySize)
            default:
                throw MobileWalletError.invalidCurve(curve)
            }
        }

        let chainCode = withUnsafeBytes(of: node.chain_code) { Data($0) }

        return ExtendedPublicKey(publicKey: publicKey, chainCode: chainCode)
    }
}

extension DerivationUtil {
    enum Constants {
        static let secp256k1PublicKeySize = 33
        static let edPublicKeySize = 32
    }
}

extension EllipticCurve {
    var curveName: String {
        switch self {
        case .secp256k1: "secp256k1"
        case .ed25519: "ed25519 cardano seed"
        case .ed25519_slip0010: "ed25519"
        default: fatalError("Unsupported curve")
        }
    }
}
