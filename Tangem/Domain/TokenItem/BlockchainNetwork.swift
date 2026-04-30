//
//  BlockchainNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

struct BlockchainNetwork: Codable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?
    let settings: BlockchainSettings?

    init(_ blockchain: Blockchain, derivationPath: DerivationPath?, settings: BlockchainSettings? = nil) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
        self.settings = settings
    }

    /// Get all derivation paths for current Blockchain
    func derivationPaths() -> [DerivationPath] {
        guard let derivationPath else {
            return []
        }

        do {
            switch blockchain {
            case .cardano(extended: true):
                let extendedPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)
                return [derivationPath, extendedPath]

            case _ where isDynamicAddressesEnabled():
                let xpubPaths = try XPUBUtils.xpubDerivationPaths(for: derivationPath)
                return [derivationPath, xpubPaths.child, xpubPaths.parent]

            default:
                return [derivationPath]
            }
        } catch {
            AppLogger.error(error: error)
            Analytics.error(error: error)
            return [derivationPath]
        }
    }

    func isDynamicAddressesEnabled() -> Bool {
        blockchain.isDynamicAddressesSupported && settings == .dynamicAddresses
    }
}

// MARK: - Equatable & Hashable

extension BlockchainNetwork: Hashable {
    /// Identity of a `BlockchainNetwork` is defined by `blockchain` + `derivationPath`.
    /// `settings` is a mutable configuration flag and must not affect equality/hashing.
    static func == (lhs: BlockchainNetwork, rhs: BlockchainNetwork) -> Bool {
        lhs.blockchain == rhs.blockchain && lhs.derivationPath == rhs.derivationPath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockchain)
        hasher.combine(derivationPath)
    }
}

// MARK: - Settings

extension BlockchainNetwork {
    func with(settings: BlockchainSettings?) -> Self {
        BlockchainNetwork(
            blockchain,
            derivationPath: derivationPath,
            settings: settings
        )
    }
}

enum BlockchainSettings: Codable, Hashable {
    /// Dynamic (xpub-derived) receive addresses are enabled for this UTXO network.
    /// When set, `BlockchainNetwork.derivationPaths()` expands to the xpub parent/child
    /// pair and the wallet manager is routed through the XPUB factories.
    /// Only meaningful for blockchains where `Blockchain.isDynamicAddressesSupported` is true.
    case dynamicAddresses
}
