//
//  HDNodeUtil.swift
//  TangemMobileWalletSdk
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
        derivationPath: DerivationPath? = nil,
        curve: EllipticCurve
    ) throws -> HDNode {
        try entropy.withUnsafeBytes { buffer in
            guard let entropyPtr = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw MobileWalletError.failedToDeriveKey
            }
            return try passphrase.withCString { passphraseStr in
                switch derivationPath {
                case .none:
                    return try entropyToHDNode(
                        entropyPtr: entropyPtr,
                        entropyCount: Int32(entropy.count),
                        passphraseStr: passphraseStr,
                        derivationPath: nil,
                        derivationPathNodesCount: 0,
                        curve: curve,
                    )
                case .some(let derivationPath):
                    // Double check that all nodes are hardened for ed25519-slip0010 curve. This case is already handled at `hdnode_helper.c`.
                    if curve == .ed25519_slip0010, derivationPath.nodes.contains(where: { !$0.isHardened }) {
                        throw MobileWalletError.failedToDeriveKey
                    }

                    let derivationPathNodes = derivationPath.nodes.map { $0.index }

                    return try derivationPathNodes.withUnsafeBufferPointer { nodesPtr in
                        guard let nodesBaseAddress = nodesPtr.baseAddress else {
                            throw MobileWalletError.failedToDeriveKey
                        }

                        return try entropyToHDNode(
                            entropyPtr: entropyPtr,
                            entropyCount: Int32(entropy.count),
                            passphraseStr: passphraseStr,
                            derivationPath: nodesBaseAddress,
                            derivationPathNodesCount: Int32(derivationPath.nodes.count),
                            curve: curve,
                        )
                    }
                }
            }
        }
    }

    /// expected to be called from nested callbacks inside makeHDNode func
    private static func entropyToHDNode(
        entropyPtr: UnsafeRawPointer,
        entropyCount: Int32,
        passphraseStr: UnsafePointer<CChar>,
        derivationPath: UnsafePointer<UInt32>?,
        derivationPathNodesCount: Int32,
        curve: EllipticCurve
    ) throws -> HDNode {
        var node = HDNode()

        let result = switch curve {
        case .ed25519:
            entropy_to_hdnode_cardano(
                entropyPtr,
                entropyCount,
                passphraseStr,
                derivationPath,
                derivationPathNodesCount,
                &node
            )
        case .ed25519_slip0010, .secp256k1:
            curve.curveName.withCString { curveStr in
                entropy_to_hdnode(
                    entropyPtr,
                    entropyCount,
                    passphraseStr,
                    curveStr,
                    derivationPath,
                    derivationPathNodesCount,
                    &node
                )
            }
        default:
            throw MobileWalletError.invalidCurve(curve)
        }

        if !result {
            throw MobileWalletError.failedToDeriveKey
        }

        return node
    }
}
