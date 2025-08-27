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

    func extract(from derivationPath: DerivationPath) -> DerivationNode? {
        return derivationPath.nodes[safe: accountDerivationNodeIndex]
    }

    /// Returns canonical derivation path for the main account (derivation index 0).
    func canonicalDerivationPath(from derivationPath: DerivationPath) -> DerivationPath {
        canonicalDerivationPath(from: derivationPath, derivationIndex: 0)
    }

    /// Returns canonical derivation path for the account with specified derivation index.
    func canonicalDerivationPath(from derivationPath: DerivationPath, derivationIndex: Int) -> DerivationPath {
        let rawIndex = UInt32(derivationIndex)
        let nodes = derivationPath.nodes
        let additionalNodesCount = min(0, DerivationPath.canonicalLength - nodes.count)
        var canonicalNodes = nodes + Array(repeating: .hardened(0), count: additionalNodesCount) // [REDACTED_TODO_COMMENT]
        canonicalNodes[accountDerivationNodeIndex] = canonicalNodes[accountDerivationNodeIndex].withRawIndex(rawIndex)

        return DerivationPath(nodes: canonicalNodes)
    }
}

// MARK: - Constants

private extension AccountDerivationPathHelper {
    enum Constants {
        /// 3th node for UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let utxoDerivationNodeIndex = 2
        /// 5th node for non-UTXO blockchains (m / purpose' / coin_type' / account' / change / address_index)
        static let nonUTXODerivationNodeIndex = 4
    }
}
