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

struct BlockchainNetwork: Codable, Hashable, Equatable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?

    init(_ blockchain: Blockchain, derivationPath: DerivationPath?) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
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

            case let blockchain where blockchain.isXPUB:
                let xpubPaths = try XPUBUtils().xpubDerivationPaths(for: derivationPath)
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
}
