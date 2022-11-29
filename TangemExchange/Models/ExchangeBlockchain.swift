//
//  ExchangeBlockchain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeBlockchain: String, CaseIterable {
    case ethereum
    case bsc = "binancecoin"
    case polygon
    case optimism
    case arbitrum
    case gnosis
    case avalanche
    case fantom
    case klayth
    case aurora

    public var networkId: String { rawValue }

    public var chainId: Int {
        switch self {
        case .ethereum:
            return 1
        case .bsc:
            return 56
        case .polygon:
            return 137
        case .optimism:
            return 10
        case .arbitrum:
            return 42161
        case .gnosis:
            return 100
        case .avalanche:
            return 43114
        case .fantom:
            return 250
        case .klayth:
            return 8217
        case .aurora:
            return 1313161554
        }
    }
}

extension ExchangeBlockchain {
    public static func convert(from chainId: Int?) -> ExchangeBlockchain? {
        guard let chainId = chainId,
              let blockchain = ExchangeBlockchain.allCases.first(where: { $0.chainId == chainId }) else {
            assertionFailure("not support blockchain")
            return nil
        }

        return blockchain
    }
}
