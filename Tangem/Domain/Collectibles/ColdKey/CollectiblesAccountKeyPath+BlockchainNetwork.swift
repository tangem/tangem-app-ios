//
//  CollectiblesAccountKeyPath+BlockchainNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemCollectibles

extension CollectiblesAccountKeyPath {
    static func blockchainNetwork(for derivationStyle: DerivationStyle?) -> BlockchainNetwork {
        BlockchainNetwork(
            .solana(
                curve: curve(for: derivationStyle),
                testnet: CollectiblesChainEnvironment.blockchain.isTestnet
            ),
            derivationPath: derivationPath
        )
    }
}
