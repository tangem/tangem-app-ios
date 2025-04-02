//
//  Chain.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension BlockaidDTO {
    enum Chain: String, Codable {
        case arbitrum
        case avalanche
        case base
        case baseSepolia = "base-sepolia"
        case bsc
        case ethereum
        case optimism
        case polygon
        case zksync
        case zksyncSepolia = "zksync-sepolia"
        case zora
        case linea
        case blast
        case scroll
        case ethereumSepolia = "ethereum-sepolia"
        case degen
        case avalancheFuji = "avalanche-fuji"
        case immutableZkevm = "immutable-zkevm"
        case immutableZkevmTestnet = "immutable-zkevm-testnet"
        case gnosis
        case worldchain
        case soneiumMinato = "soneium-minato"
        case ronin
        case apechain
        case zeroNetwork = "zero-network"
        case berachain
        case berachainBartio = "berachain-bartio"
        case ink
        case inkSepolia = "ink-sepolia"
        case abstract
        case abstractTestnet = "abstract-testnet"
        case soneium
        case unichain
        case sei
    }
}

extension BlockaidDTO.Chain {
    init?(blockchain: Blockchain) {
        switch blockchain {
        case .ethereum(let testnet) where testnet == false:
            self = .ethereum
        case .ethereum(let testnet) where testnet == true:
            self = .ethereumSepolia
        case .bsc(let testnet) where testnet == false:
            self = .bsc
        case .polygon(let testnet) where testnet == false:
            self = .polygon
        case .avalanche(let testnet) where testnet == false:
            self = .avalanche
        case .avalanche(let testnet) where testnet == true:
            self = .avalancheFuji
        case .arbitrum(let testnet) where testnet == false:
            self = .arbitrum
        case .gnosis:
            self = .gnosis
        case .optimism(let testnet) where testnet == false:
            self = .optimism
        case .zkSync(let testnet) where testnet == false:
            self = .zksync
        case .zkSync(let testnet) where testnet == true:
            self = .zksyncSepolia
        case .base(let testnet) where testnet == false:
            self = .base
        case .base(let testnet) where testnet == true:
            self = .baseSepolia
        case .blast(let testnet) where testnet == false:
            self = .blast
        case .sei(let testnet) where testnet == false:
            self = .sei
        case .apeChain(let testnet) where testnet == false:
            self = .apechain
        default:
            return nil
        }
    }
}
