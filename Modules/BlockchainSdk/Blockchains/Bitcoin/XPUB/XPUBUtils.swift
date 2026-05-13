//
//  XPUBUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public enum XPUBUtils {
    public static func generateXPUB(key: Wallet.PublicKey.XPUBKey, isTestnet: Bool) throws -> String {
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

    public static func prefix(blockchain: Blockchain) throws -> Prefix {
        switch blockchain {
        // `bitcoin` and `litecoin` uses WPKH as default address key.
        case .bitcoin, .litecoin:
            return .wpkh
        case let blockchain where blockchain.isUTXO:
            return .pkh
        default:
            throw Error.xpubNotSupported
        }
    }

    /// Returns additional derivation paths needed for XPUB generation.
    /// - **child** (account-level): e.g. `m/84'/0'/0'`
    /// - **parent**: one level above child, e.g. `m/84'/0'`
    ///
    /// Supports original paths with 3, 4, or 5 nodes:
    /// - 5 nodes (`m/84'/0'/0'/0/0`): child = drop 2, parent = drop 3
    /// - 4 nodes (`m/84'/0'/0'/0`):   child = drop 1, parent = drop 2
    /// - 3 nodes (`m/84'/0'/0'`):      child = self,   parent = drop 1
    public static func xpubDerivationPaths(for derivationPath: DerivationPath) throws -> (child: DerivationPath, parent: DerivationPath) {
        guard (3 ... 5).contains(derivationPath.nodes.count) else {
            throw Error.wrongDerivationPath
        }

        let childPath = DerivationPath(nodes: Array(derivationPath.nodes.prefix(3)))
        let parentPath = DerivationPath(nodes: Array(derivationPath.nodes.prefix(2)))

        return (child: childPath, parent: parentPath)
    }
}

// MARK: - Types

extension XPUBUtils {
    public enum Prefix {
        case pkh
        case wpkh

        func wrap(xpub: String) -> String {
            switch self {
            case .pkh: "pkh(\(xpub))"
            case .wpkh: "wpkh(\(xpub))"
            }
        }
    }

    enum Error: LocalizedError {
        case wrongDerivationPath
        case failedToGenerateXPUB
        case xpubNotSupported

        var errorDescription: String? {
            switch self {
            case .wrongDerivationPath: "Wrong derivation path"
            case .failedToGenerateXPUB: "Failed to generate XPUB"
            case .xpubNotSupported: "XPUB not supported"
            }
        }
    }
}
