//
//  XPUBAddressesDerivationHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct XPUBAddressesDerivationHelper {
    let accountDerivationPath: DerivationPath
    let usedDerivations: [DerivationPath]

    /// Resolves the next unused receive and change derivation paths given the account-level
    /// derivation path (e.g. `m/84'/0'/0'`) and a list of used derivation paths
    /// - Parameters:
    ///   - accountDerivationPath: The derivation path of the account key (e.g. `m/84'/0'/0'`)
    ///   - usedDerivations: Used derivation paths
    func resolveDerivationPath(chain: Chain) -> DerivationPath {
        let usedIndices = parseUsedIndices(from: usedDerivations, chain: chain)
        let nextIndex = findFirstUnusedIndex(in: usedIndices)
        let nodes = Self.addressNodes(chain: chain, index: nextIndex)

        return DerivationPath(nodes: accountDerivationPath.nodes + [nodes.chainNode, nodes.addressNode])
    }

    static func addressPosition(of path: DerivationPath) -> (chain: Chain, index: UInt32)? {
        let nodes = path.nodes

        guard nodes.count >= 2 else {
            return nil
        }

        // Both change and index nodes must be non-hardened in BIP-44
        switch (nodes[nodes.count - 2], nodes[nodes.count - 1]) {
        case (.nonHardened(let changeValue), .nonHardened(let indexValue)):
            guard let chain = Chain(rawValue: changeValue) else {
                return nil
            }

            return (chain: chain, index: indexValue)
        case (.hardened, _),
             (_, .hardened):
            return nil
        }
    }

    static func addressNodes(of path: DerivationPath) -> (chainNode: DerivationNode, addressNode: DerivationNode)? {
        guard let position = addressPosition(of: path) else {
            return nil
        }

        return addressNodes(chain: position.chain, index: position.index)
    }
}

// MARK: - Private

private extension XPUBAddressesDerivationHelper {
    static func addressNodes(chain: Chain, index: UInt32) -> (chainNode: DerivationNode, addressNode: DerivationNode) {
        (chainNode: .nonHardened(chain.rawValue), addressNode: .nonHardened(index))
    }

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
            guard let position = Self.addressPosition(of: path), position.chain == chain else {
                continue
            }

            indices.insert(position.index)
        }

        return indices
    }
}

// MARK: - Nested Types

extension XPUBAddressesDerivationHelper {
    /// BIP-44 chain type
    enum Chain: UInt32 {
        /// External chain (receive addresses): `m/x'/x'/x'/0/<index>`
        case external = 0
        /// Internal chain (change addresses): `m/x'/x'/x'/1/<index>`
        case `internal` = 1
    }
}
