//
//  SupportedExchangeBlockchain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

struct SwappingAvailableUtils {
    private let supportedBlockchains: [ExchangeBlockchain] = [
        .ethereum,
        .bsc,
        .polygon,
        .optimism,
//        .arbitrum, [REDACTED_TODO_COMMENT]
        .gnosis,
        .avalanche,
        .fantom,
    ]

    func isSupportSwapping(blockchainNetworkId: String) -> Bool {
        // toggleIsOn
        guard FeatureProvider.isAvailable(.exchange) else {
            return false
        }

        guard let blockchain = ExchangeBlockchain(networkId: blockchainNetworkId) else {
            return false
        }

        return supportedBlockchains.contains(blockchain)
    }
}
