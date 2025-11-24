//
//  PendingDerivationHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

/// Shares some common logic for PendingDerivation creation and processing between `Legacy` and `Accounts` modes.
enum PendingDerivationHelper {
    static func pendingDerivation(network: BlockchainNetwork, keys: [KeyInfo]) -> PendingDerivation? {
        let curve = network.blockchain.curve

        let derivationPaths = network.derivationPaths()
        guard let masterKey = keys.first(where: { $0.curve == curve }) else {
            return nil
        }

        let pendingDerivationPaths = derivationPaths.filter { derivationPath in
            !masterKey.derivedKeys.keys.contains { $0 == derivationPath }
        }
        guard pendingDerivationPaths.isNotEmpty else {
            return nil
        }

        return PendingDerivation(
            network: network,
            masterKey: masterKey,
            paths: pendingDerivationPaths
        )
    }

    static func pendingDerivationsKeyedByPublicKeys(_ derivations: [PendingDerivation]) -> [Data: [DerivationPath]] {
        return derivations.reduce(into: [:]) { dict, derivation in
            dict[derivation.masterKey.publicKey, default: []] += derivation.paths
        }
    }
}
