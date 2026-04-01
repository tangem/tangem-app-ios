//
//  DynamicAddressesDerivationHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct DynamicAddressesDerivationHelper {
    let accountDerivationPath: DerivationPath
    let usedDerivations: [DerivationPath]

    /// Resolves the next unused receive and change derivation paths given the account-level
    /// derivation path (e.g. `m/84'/0'/0'`) and a list of used derivation paths
    /// - Parameters:
    ///   - accountDerivationPath: The derivation path of the account key (e.g. `m/84'/0'/0'`)
    ///   - usedDerivations: Used derivation paths
    func resolveDerivationPath(chain: Chain) -> DerivationPath {
        let usedIndices = parseUsedIndices(from: usedDerivations, chain: chain)
        let chainNode: DerivationNode = .nonHardened(chain.rawValue)
        let nextIndex = findFirstUnusedIndex(in: usedIndices)
        let addressNode: DerivationNode = .nonHardened(nextIndex)

        return DerivationPath(nodes: accountDerivationPath.nodes + [chainNode, addressNode])
    }
}

// MARK: - Private

private extension DynamicAddressesDerivationHelper {
    /// Finds the first unused index (starting from 0) not present in the given set.
    func findFirstUnusedIndex(in usedIndices: Set<UInt32>) -> UInt32 {
        var index: UInt32 = 0
        while usedIndices.contains(index) {
            index += 1
        }
        return index
    }

    /// Extracts used address indices for the given chain from derivation paths.
    /// Looks at the last two nodes of each path: `change` and `address_index`.
    func parseUsedIndices(from paths: [DerivationPath], chain: Chain) -> Set<UInt32> {
        var indices = Set<UInt32>()

        for path in paths {
            let nodes = path.nodes
            guard nodes.count >= 2 else { continue }

            let changeNode = nodes[nodes.count - 2]
            let indexNode = nodes[nodes.count - 1]

            // Both change and index nodes must be non-hardened in BIP-44
            guard case .nonHardened(let changeValue) = changeNode,
                  case .nonHardened(let indexValue) = indexNode,
                  changeValue == chain.rawValue else {
                continue
            }

            indices.insert(indexValue)
        }

        return indices
    }
}

// MARK: - Nested Types

extension DynamicAddressesDerivationHelper {
    /// BIP-44 chain type
    enum Chain: UInt32 {
        /// External chain (receive addresses): `m/x'/x'/x'/0/<index>`
        case external = 0
        /// Internal chain (change addresses): `m/x'/x'/x'/1/<index>`
        case `internal` = 1
    }
}
