//
//  AccountDerivationNodeExtractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation
import BlockchainSdk

struct AccountDerivationNodeExtractor {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    func extract(from derivationPath: DerivationPath) -> DerivationNode? {
        let derivationNodeIndex = blockchain.isUTXO
            ? Constants.utxoDerivationNodeIndex
            : Constants.nonUTXODerivationNodeIndex

        return derivationPath.nodes[safe: derivationNodeIndex]
    }
}

// MARK: - Constants

private extension AccountDerivationNodeExtractor {
    enum Constants {
        static let utxoDerivationNodeIndex = 2
        static let nonUTXODerivationNodeIndex = 4
    }
}
