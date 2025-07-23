//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TrezorCrypto
import TangemSdk

enum HDNodeUtil {
    static func makeHDNode(
        entropy: Data,
        passphrase: String = "",
        derivationPath: DerivationPath,
        curve: EllipticCurve
    ) throws -> HDNode {
        var node = HDNode()

        try entropy.withUnsafeBytes { buffer in
            guard let entropyPtr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw HotWalletError.failedToDeriveKey
            }

            try passphrase.withCString { passphraseStr in
                // Convert derivation path nodes to an array of indices
                let derivationPathNodes = derivationPath.nodes.map { $0.index }

                try derivationPathNodes.withUnsafeBufferPointer { nodesPtr in
                    guard let nodesBaseAddress = nodesPtr.baseAddress else {
                        throw HotWalletError.failedToDeriveKey
                    }

                    let result: Bool

                    switch curve {
                    case .ed25519:
                        result = entropy_to_hdnode_cardano(
                            entropyPtr,
                            Int32(entropy.count),
                            passphraseStr,
                            nodesBaseAddress,
                            Int32(derivationPath.nodes.count),
                            &node
                        )
                    case .ed25519_slip0010, .secp256k1:
                        result = curve.curveName.withCString { curveStr in
                            entropy_to_hdnode(
                                entropyPtr,
                                Int32(entropy.count),
                                passphraseStr,
                                curveStr,
                                nodesBaseAddress,
                                Int32(derivationPath.nodes.count),
                                &node
                            )
                        }
                    default:
                        throw HotWalletError.invalidCurve(curve)
                    }

                    if !result {
                        throw HotWalletError.failedToDeriveKey
                    }
                }
            }
        }

        return node
    }
}
