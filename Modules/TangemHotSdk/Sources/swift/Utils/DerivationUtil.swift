//
//  DerivationUtil.swift
//  TangemHotSdk
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
            throw HotWalletError.tangemSdk(.unsupportedCurve)
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
        case .ed25519:
            return try publicKeyCardano(
                entropy: entropy,
                passphrase: passphrase,
                derivationPath: derivationPath,
                curve: curve
            )
        case .secp256k1, .ed25519_slip0010:
            let result = try publicKeyDefault(
                entropy: entropy,
                passphrase: passphrase,
                derivationPath: derivationPath,
                curve: curve
            )

            return result
        default:
            throw HotWalletError.tangemSdk(.unsupportedCurve)
        }
    }
    
    static func curve(for masterKey: Data, entropy: Data, passphrase: String) -> EllipticCurve? {
        let curves: [EllipticCurve] = [.secp256k1, .ed25519, .ed25519_slip0010]
        
        return curves
            .first { curve in
                guard let key = try? Self.masterKey(from: curve, entropy: entropy, passphrase: passphrase) else {
                    return false
                }
                return key == masterKey
            }
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

        let publicKey: Data

        switch curve {
        case .ed25519_slip0010:
            var pubKey = [UInt8](repeating: 0, count: Constants.edPublicKeySize)

            pubKey.withUnsafeMutableBufferPointer { publicKeyBuf in
                ed25519_publickey(&node.private_key, publicKeyBuf.baseAddress)
            }

            publicKey = Data(pubKey)
        case .secp256k1:
            var pubKey = [UInt8](repeating: 0, count: Constants.secp256k1PublicKeySize)

            let result = pubKey.withUnsafeMutableBufferPointer { pubBuf in
                ecdsa_get_public_key33(
                    node.curve?.pointee.params,
                    &node.private_key,
                    pubBuf.baseAddress
                )
            }

            guard result == 0 else {
                throw HotWalletError.failedToDeriveKey
            }

            publicKey = Data(pubKey)
        case .ed25519:
            var pubKey = [UInt8](repeating: 0, count: DerivationUtil.Constants.edPublicKeySize)

            try pubKey.withUnsafeMutableBytes { publicKeyBuf in
                guard let publicKeyPtr = publicKeyBuf.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw HotWalletError.failedToDeriveKey
                }
                return ed25519_publickey_ext(
                    &node.private_key,
                    publicKeyPtr
                )
            }

            publicKey = Data(pubKey)
        default:
            throw HotWalletError.invalidCurve(curve)
        }

        let chainCode = withUnsafeBytes(of: node.chain_code) { Data($0) }

        return ExtendedPublicKey(publicKey: publicKey, chainCode: chainCode)
    }

    static func publicKeyCardano(
        entropy: Data,
        passphrase: String,
        derivationPath: DerivationPath?,
        curve: EllipticCurve
    ) throws -> ExtendedPublicKey {
        guard case .ed25519 = curve else {
            throw HotWalletError.invalidCurve(curve)
        }

        let spendingKey = try publicKeyDefault(
            entropy: entropy,
            passphrase: passphrase,
            derivationPath: derivationPath,
            curve: curve
        )

        guard derivationPath != nil else {
            return spendingKey
        }

        let stakingKey = try publicKeyDefault(
            entropy: entropy,
            passphrase: passphrase,
            derivationPath: CardanoUtil.stakingDerivationPath,
            curve: curve
        )

        let publicKey = Data(
            spendingKey.publicKey + spendingKey.chainCode + stakingKey.publicKey + stakingKey.chainCode
        )

        return ExtendedPublicKey(publicKey: publicKey, chainCode: spendingKey.chainCode)
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
