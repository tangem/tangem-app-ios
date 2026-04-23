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

struct BlockchainNetwork: Hashable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?
    let derivationMode: DerivationMode

    init(_ blockchain: Blockchain, derivationPath: DerivationPath?, derivationMode: DerivationMode = .plain) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
        self.derivationMode = derivationMode
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
        blockchain.isDynamicAddressesSupported && derivationMode == .xpub
    }
}

// MARK: - Codable

extension BlockchainNetwork: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockchain = try container.decode(Blockchain.self, forKey: .blockchain)
        derivationPath = try container.decodeIfPresent(DerivationPath.self, forKey: .derivationPath)

        // Have to use custom decodable with fallback to `DerivationMode.plain`
        derivationMode = try container.decodeIfPresent(DerivationMode.self, forKey: .derivationMode) ?? .plain
    }
}

// MARK: - DerivationMode

extension BlockchainNetwork {
    func with(derivationMode: DerivationMode) -> Self {
        BlockchainNetwork(
            blockchain,
            derivationPath: derivationPath,
            derivationMode: derivationMode
        )
    }
}

// MARK: - DerivationMode

extension BlockchainNetwork {
    enum DerivationMode: Codable {
        case plain
        case xpub
    }
}
