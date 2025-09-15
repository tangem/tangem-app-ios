//
//  SignUtil.swift
//  TangemMobileWalletSdk
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
            var signature = [UInt8](repeating: 0, count: Constants.signatureLength)
            var recoveryByte: UInt8 = 0

            try hash.withUnsafeBytes {
                guard let hashBaseAddress = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    throw MobileWalletError.failedToSignHash
                }

                let result: Int32

                if node.curve.pointee.params != nil {
                    result = hdnode_sign_digest(&node, hashBaseAddress, &signature, &recoveryByte, nil)
                } else {
                    result = hdnode_sign(
                        &node,
                        hashBaseAddress,
                        UInt32(hash.count),
                        HASHER_SHA2D,
                        &signature,
                        &recoveryByte,
                        nil
                    )
                }

                guard result == 0 else {
                    throw MobileWalletError.failedToSignHash
                }
            }

            return Data(signature)
        }
    }
}

private extension SignUtil {
    enum Constants {
        static let signatureLength = 64
    }
}
