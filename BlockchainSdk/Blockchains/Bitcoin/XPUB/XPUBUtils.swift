//
//  XPUBUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct XPUBUtils {
    public init() {}

    public func generateXPUB(key: Wallet.PublicKey.XPUBKey, isTestnet: Bool) throws -> String {
        let childPublicKey = key.child.extendedPublicKey.publicKey
        let childChainCode = key.child.extendedPublicKey.chainCode
        let parentPublicKey = key.parent.extendedPublicKey.publicKey

        guard let lastChildNode = key.child.path.nodes.last else {
            throw Error.failedToGenerateXPUB
        }

        let depth = key.child.path.nodes.count
        let childNumber = lastChildNode.index
        let parentFingerprint = parentPublicKey.sha256Ripemd160.prefix(4)

        let extendedKey = try ExtendedPublicKey(
            publicKey: childPublicKey,
            chainCode: childChainCode,
            depth: depth,
            parentFingerprint: parentFingerprint,
            childNumber: childNumber
        )

        return try extendedKey.serialize(for: isTestnet ? .testnet : .mainnet)
    }

    /// Returns additional derivation paths needed for XPUB generation.
    /// - **child** (account-level): leaf path with last 2 nodes dropped, e.g. `m/84'/0'/0'/0/0` → `m/84'/0'/0'`
    /// - **parent**: one level above child, e.g. `m/84'/0'/0'` → `m/84'/0'`
    public func xpubDerivationPaths(for derivationPath: DerivationPath) throws -> (child: DerivationPath, parent: DerivationPath) {
        guard derivationPath.nodes.count >= 4 else {
            throw Error.derivationPathTooShort
        }

        let childPath = derivationPath.dropLastNode(count: 2)
        let parentPath = derivationPath.dropLastNode(count: 3)

        return (child: childPath, parent: parentPath)
    }
}

// MARK: - Error

extension XPUBUtils {
    enum Error: String, LocalizedError {
        case derivationPathTooShort
        case failedToGenerateXPUB

        var errorDescription: String? {
            rawValue
        }
    }
}
