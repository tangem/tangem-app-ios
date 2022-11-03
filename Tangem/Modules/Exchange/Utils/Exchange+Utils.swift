//
//  Exchange+Utils.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ExchangeSdk
import BlockchainSdk

extension ExchangeBlockchain {
    static func convert(from blockchainNetwork: BlockchainNetwork) -> ExchangeBlockchain {
        switch blockchainNetwork.blockchain {
        case .ethereum:
            return .ethereum
        case .bsc:
            return .bsc
        case .polygon:
            return .polygon
        case .avalanche:
            return .avalanche
        case .fantom:
            return .fantom
        case .arbitrum:
            return .arbitrum
        case .optimism:
            return .optimism
        case .gnosis:
            return .gnosis
        default:
            fatalError("Unknown blockchain")
        }
    }
}
