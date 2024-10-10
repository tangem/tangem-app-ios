//
//  BlockchainNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdkLocal

struct BlockchainNetwork: Codable, Hashable, Equatable {
    let blockchain: Blockchain
    let derivationPath: DerivationPath?

    init(_ blockchain: Blockchain, derivationPath: DerivationPath?) {
        self.blockchain = blockchain
        self.derivationPath = derivationPath
    }

    // Get all derivation paths for current Blockchain
    func derivationPaths() -> [DerivationPath] {
        guard let derivationPath else {
            return []
        }

        // If we use the extended cardano then
        // we should have two derivations for collect correct PublicKey
        guard case .cardano(let extended) = blockchain, extended else {
            return [derivationPath]
        }

        do {
            let extendedPath = try CardanoUtil().extendedDerivationPath(for: derivationPath)
            return [derivationPath, extendedPath]
        } catch {
            AppLog.shared.error(error)
            return [derivationPath]
        }
    }
}
