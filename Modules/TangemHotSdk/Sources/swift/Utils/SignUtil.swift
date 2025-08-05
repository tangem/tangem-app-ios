//
//  SignUtil.swift
//  TangemHotSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import TangemSdk
import TrezorCrypto

enum SignUtil {
    static func sign(
        entropy: Data,
        passphrase: String = "",
        hashes: [Data],
        curve: EllipticCurve,
        derivationPath: DerivationPath?
    ) throws -> [Data] {
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

        return try hashes.compactMap { hash -> Data? in
            switch curve {
            case .secp256k1:
                try signSecp256k1(hash: hash, node: &node)
            case .ed25519:
                try signEd25519Cardano(hash: hash, node: &node)
            case .ed25519_slip0010:
                try signEd25519(hash: hash, node: &node)
            default:
                throw HotWalletError.tangemSdk(.unsupportedCurve)
            }
        }
    }

    private static func signSecp256k1(hash: Data, node: inout HDNode) throws -> Data {
        var signature = [UInt8](repeating: 0, count: Constants.signatureLength)
        var recoveryByte: UInt8 = 0

        let signResult = try hash.withUnsafeBytes {
            guard let hashBaseAddress = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw HotWalletError.failedToSignHash
            }

            return ecdsa_sign_digest(
                node.curve.pointee.params,
                &node.private_key,
                hashBaseAddress,
                &signature,
                &recoveryByte,
                nil
            )
        }

        guard signResult == 0 else {
            throw HotWalletError.failedToSignHash
        }
        return try Secp256k1Signature(with: Data(signature)).normalize()
    }

    private static func signEd25519(hash: Data, node: inout HDNode) throws -> Data {
        var signature = [UInt8](repeating: 0, count: Constants.signatureLength)

        try hash.withUnsafeBytes {
            guard let hashBaseAddress = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw HotWalletError.failedToSignHash
            }

            tangem_vendored_ed25519_sign(
                hashBaseAddress,
                hash.count,
                &node.private_key,
                &signature
            )
        }

        return Data(signature)
    }

    private static func signEd25519Cardano(hash: Data, node: inout HDNode) throws -> Data {
        var signature = [UInt8](repeating: 0, count: Constants.signatureLength)

        try hash.withUnsafeBytes {
            guard let hashBaseAddress = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw HotWalletError.failedToSignHash
            }

            ed25519_sign_ext(
                hashBaseAddress,
                hash.count,
                &node.private_key,
                &node.private_key_extension,
                &signature
            )
        }

        return Data(signature)
    }
}

private extension SignUtil {
    enum Constants {
        static let signatureLength = 64
    }
}
