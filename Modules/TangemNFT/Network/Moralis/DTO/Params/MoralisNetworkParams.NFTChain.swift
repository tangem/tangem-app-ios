//
//  MoralisNetworkParams.NFTChain.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension MoralisNetworkParams {
    /// This list is taken from `docs.moralis.com` and it's actual on 05.03.2025.
    enum NFTChain: Encodable {
        case eth
        case sepolia
        case holesky
        case polygon(isAmoy: Bool)
        case bsc(isTestnet: Bool)
        case avalanche
        case fantom
        case palm
        case cronos
        case arbitrum
        case gnosis(isTestnet: Bool)
        case chiliz(isTestnet: Bool)
        case base(isSepolia: Bool)
        case optimism
        case linea(isSepolia: Bool)
        case moonbeam
        case moonriver
        case moonbase
        case flow(isTestnet: Bool)
        case ronin(isTestnet: Bool)
        case lisk(isSepolia: Bool)

        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .eth:
                try container.encode("eth")
            case .sepolia:
                try container.encode("sepolia")
            case .holesky:
                try container.encode("holesky")
            case .polygon(let isAmoy):
                try container.encode(isAmoy ? "polygon amoy" : "polygon")
            case .bsc(let isTestnet):
                try container.encode(isTestnet ? "bsc testnet" : "bsc")
            case .avalanche:
                try container.encode("avalanche")
            case .fantom:
                try container.encode("fantom")
            case .palm:
                try container.encode("palm")
            case .cronos:
                try container.encode("cronos")
            case .arbitrum:
                try container.encode("arbitrum")
            case .gnosis(let isTestnet):
                try container.encode(isTestnet ? "gnosis testnet" : "gnosis")
            case .chiliz(let isTestnet):
                try container.encode(isTestnet ? "chiliz testnet" : "chiliz")
            case .base(let isSepolia):
                try container.encode(isSepolia ? "base sepolia" : "base")
            case .optimism:
                try container.encode("optimism")
            case .linea(let isSepolia):
                try container.encode(isSepolia ? "linea sepolia" : "linea")
            case .moonbeam:
                try container.encode("moonbeam")
            case .moonriver:
                try container.encode("moonriver")
            case .moonbase:
                try container.encode("moonbase")
            case .flow(let isTestnet):
                try container.encode(isTestnet ? "flow-testnet" : "flow")
            case .ronin(let isTestnet):
                try container.encode(isTestnet ? "ronin-testnet" : "ronin")
            case .lisk(let isSepolia):
                try container.encode(isSepolia ? "lisk-sepolia" : "lisk")
            }
        }
    }
}
