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
    let derivationLevel: DerivationLevel

    init(_ blockchain: Blockchain, derivationPath: DerivationPath?, derivationLevel: DerivationLevel = .plain) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
        self.derivationLevel = derivationLevel
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
        blockchain.isDynamicAddressesSupported && derivationLevel == .xpub
    }
}

// MARK: - Codable

extension BlockchainNetwork: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockchain = try container.decode(Blockchain.self, forKey: .blockchain)
        derivationPath = try container.decodeIfPresent(DerivationPath.self, forKey: .derivationPath)

        // Have to use custom decodable with fallback to `DerivationLevel.plain`
        derivationLevel = try container.decodeIfPresent(DerivationLevel.self, forKey: .derivationLevel) ?? .plain
    }
}

// MARK: - DerivationLevel

extension BlockchainNetwork {
    enum DerivationLevel: Codable {
        case plain
        case xpub
    }
}
