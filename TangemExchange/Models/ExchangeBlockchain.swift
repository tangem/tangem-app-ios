//
//  ExchangeBlockchain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public enum ExchangeBlockchain: String, Hashable, CaseIterable {
    case ethereum
    case bsc
    case polygon
    case optimism
    case arbitrum
    case gnosis
    case avalanche
    case fantom
    case klayth
    case aurora

    public init?(networkId: String) {
        self.init(rawValue: networkId)
    }

    public var networkId: String { rawValue }

    public var chainId: Int {
        switch self {
        case .ethereum: return 1
        case .bsc: return 56
        case .polygon: return 137
        case .optimism: return 10
        case .arbitrum: return 42161
        case .gnosis: return 100
        case .avalanche: return 43114
        case .fantom: return 250
        case .klayth: return 8217
        case .aurora: return 1313161554
        }
    }

    public var id: String {
        switch self {
        case .ethereum: return "ethereum"
        case .bsc: return "binancecoin"
        case .polygon: return "matic-network"
        case .avalanche: return "avalanche-2"
        case .fantom: return "fantom"
        case .arbitrum: return "arbitrum-one"
        case .gnosis: return "xdai"
        case .optimism: return "optimistic-ethereum"
        case .klayth: return ""
        case .aurora: return ""
        }
    }
}
