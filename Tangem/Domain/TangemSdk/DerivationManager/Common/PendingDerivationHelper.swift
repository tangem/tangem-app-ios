//
//  PendingDerivationHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import struct TangemSdk.DerivationPath

/// Shares some common logic for PendingDerivation creation and processing between `Legacy` and `Accounts` modes.
enum PendingDerivationHelper {
    static func pendingDerivations(network: BlockchainNetwork, keys: [KeyInfo]) -> [PendingDerivation] {
        let curve = network.blockchain.curve
        let derivationPaths = network.derivationPaths()

        // In some rare edge cases (old wallets, etc) there might be multiple master keys with the same curve,
        // so we need to check all of them and create pending derivations for each of them if needed.
        return keys
            .filter { $0.curve == curve }
            .compactMap { masterKey in
                guard let paths = pendingDerivationPaths(from: derivationPaths, for: masterKey).nilIfEmpty else {
                    return nil
                }

                return PendingDerivation(
                    network: network,
                    masterKey: masterKey,
                    paths: paths
                )
            }
    }

    static func pendingDerivationPathsKeyedByPublicKeys(_ derivations: [PendingDerivation]) -> [Data: [DerivationPath]] {
        return derivations.reduce(into: [:]) { dict, derivation in
            dict[derivation.masterKey.publicKey, default: []] += derivation.paths
        }
    }

    private static func pendingDerivationPaths(from derivationPaths: [DerivationPath], for masterKey: KeyInfo) -> [DerivationPath] {
        return derivationPaths.filter { derivationPath in
            !masterKey.derivedKeys.keys.contains { $0 == derivationPath }
        }
    }
}
