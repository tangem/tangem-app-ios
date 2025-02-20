//
//  APINodeInfoResolver.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct APINodeInfoResolver {
    let blockchain: Blockchain
    let config: BlockchainSdkConfig

    func resolve(for providerType: NetworkProviderType) -> NodeInfo? {
        switch providerType {
        case .public(let link):
            return PublicAPIResolver(blockchain: blockchain)
                .resolve(for: link)
        case .nowNodes:
            return NowNodesAPIResolver(apiKey: config.nowNodesApiKey)
                .resolve(for: blockchain)
        case .quickNode:
            return QuickNodeAPIResolver(config: config)
                .resolve(for: blockchain)
        case .getBlock:
            return GetBlockAPIResolver(credentials: config.getBlockCredentials)
                .resolve(for: blockchain)
        case .infura:
            return InfuraAPIResolver(config: config)
                .resolve(for: blockchain)
        case .ton:
            return TONAPIResolver(config: config)
                .resolve(blockchain: blockchain)
        case .tron:
            return TronAPIResolver(config: config)
                .resolve(blockchain: blockchain)
        case .adalite, .tangemRosetta:
            return CardanoAPIResolver()
                .resolve(providerType: providerType, blockchain: blockchain)
        case .tangemChia, .fireAcademy, .tangemChia3:
            return ChiaAPIResolver(config: config)
                .resolve(providerType: providerType, blockchain: blockchain)
        case .arkhiaHedera:
            return HederaAPIResolver(config: config)
                .resolve(providerType: providerType, blockchain: blockchain)
        case .kaspa:
            return KaspaAPIResolver(config: config)
                .resolve(blockchain: blockchain)
        case .onfinality:
            return OnfinalityAPIResolver(config: config)
                .resolve()
        case .dwellir:
            return DwellirAPIResolver(config: config)
                .resolve()
        case .koinos:
            return KoinosAPIResolver(config: config)
                .resolve(blockchain: blockchain)
        case .tangemAlephium:
            return AlephiumAPIResolver(config: config)
                .resolve(providerType: .tangemAlephium, blockchain: blockchain)
        case .blockchair, .blockcypher, .solana:
            return nil
        }
    }
}
