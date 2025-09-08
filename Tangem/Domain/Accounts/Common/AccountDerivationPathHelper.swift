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

    private var accountDerivationNodeIndex: Int {
        blockchain.isUTXO ? Constants.utxoDerivationNodeIndex : Constants.nonUTXODerivationNodeIndex
    }

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func extractAccountDerivationNode(from derivationPath: DerivationPath?) -> DerivationNode? {
        return derivationPath?.nodes[safe: accountDerivationNodeIndex]
    }

    /// Returns canonical derivation path for the main account (account derivation index is unchanged).
    func canonicalDerivationPath(from derivationPath: DerivationPath) -> DerivationPath {
        let currentNodes = derivationPath.nodes
        let additionalNodesCount = max(0, DerivationPath.canonicalLength - currentNodes.count)
        // [REDACTED_TODO_COMMENT]
        let canonicalNodes = currentNodes + Array(repeating: .hardened(0), count: additionalNodesCount)

        return DerivationPath(nodes: canonicalNodes)
    }

    /// Returns canonical derivation path for the account with specified derivation index.
    func canonicalDerivationPath(from derivationPath: DerivationPath, derivationIndexValue: Int) -> DerivationPath {
        let rawIndexValue = UInt32(derivationIndexValue)
        let canonicalDerivationPath = canonicalDerivationPath(from: derivationPath)
        var canonicalNodes = canonicalDerivationPath.nodes
        canonicalNodes[accountDerivationNodeIndex] = canonicalNodes[accountDerivationNodeIndex].withRawIndex(rawIndexValue)

        return DerivationPath(nodes: canonicalNodes)
    }
}

// MARK: - Constants

private extension AccountDerivationPathHelper {
    enum Constants {
        /// 3rd node for UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let utxoDerivationNodeIndex = 2
        /// 5th node for non-UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let nonUTXODerivationNodeIndex = 4
    }
}
