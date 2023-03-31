//
//  SupportedSwappingBlockchain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemSwapping
import BlockchainSdk

struct SwappingAvailableUtils {
    private let supportedBlockchains: [SwappingBlockchain] = [
        .ethereum,
        .bsc,
        .polygon,
        .optimism,
        .arbitrum,
        .gnosis,
        .avalanche,
        .fantom,
    ]

    func canSwap(blockchainNetworkId: String) -> Bool {
        // Checking that toggle is on
        guard FeatureProvider.isAvailable(.exchange) else {
            return false
        }

        guard let blockchain = SwappingBlockchain(networkId: blockchainNetworkId) else {
            return false
        }

        return supportedBlockchains.contains(blockchain)
    }
}
