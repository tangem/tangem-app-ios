//
//  AccountDerivationPathHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

struct AccountDerivationPathHelper {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func extractAccountDerivationNode(from derivationPath: DerivationPath?) -> DerivationNode? {
        guard let derivationPath else {
            return nil
        }

        let accountDerivationNodeIndex = accountDerivationNodeIndex(for: derivationPath)

        return derivationPath.nodes[accountDerivationNodeIndex]
    }

    func makeDerivationPath(from derivationPath: DerivationPath, forAccountWithIndex accountIndex: Int) -> DerivationPath {
        let rawAccountIndex = UInt32(accountIndex)
        let accountDerivationNodeIndex = accountDerivationNodeIndex(for: derivationPath)
        var nodes = derivationPath.nodes

        nodes[accountDerivationNodeIndex] = nodes[accountDerivationNodeIndex].withRawIndex(rawAccountIndex)

        return DerivationPath(nodes: nodes)
    }

    private func accountDerivationNodeIndex(for derivationPath: DerivationPath) -> Int {
        let nodes = derivationPath.nodes

        switch nodes.count {
        case 5 where blockchain.isUTXO:
            return Constants.utxoDerivationNodeIndex
        case 3 where !blockchain.isUTXO,
             5 where !blockchain.isUTXO:
            // For non-UTXO blockchains we use the last node as account node (either 3rd or 5th)
            return nodes.count - 1
        case 4 where blockchain.isTezos:
            // Some non-UTXO blockchains (like Tezos) have 4 nodes in the derivation path
            return Constants.nonUTXONonStandardDerivationNodeIndex
        default:
            // Currently, there are no blockchains with other derivation path nodes count
            // Such blockchains should be handled here explicitly
            assertionFailure("Unexpected derivation path nodes count: \(nodes.count) for blockchain: \(blockchain.displayName)")
            return max(0, nodes.count - 1)
        }
    }
}

// MARK: - Constants

private extension AccountDerivationPathHelper {
    enum Constants {
        /// 3rd node for UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let utxoDerivationNodeIndex = 2
        /// 3rd node for some non-UTXO blockchains (like Tezos) which have 4 nodes (m / purpose' / coin_type' / account' / unspecified)
        static let nonUTXONonStandardDerivationNodeIndex = 2
    }
}

// MARK: - Convenience extensions

private extension Blockchain {
    var isTezos: Bool {
        if case .tezos = self {
            return true
        }
        return false
    }
}
