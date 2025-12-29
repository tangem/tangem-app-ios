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
    let keysConfig: BlockchainSdkKeysConfig

    func resolve(for providerType: NetworkProviderType) -> NodeInfo? {
        switch providerType {
        case .public(let link):
            return PublicAPIResolver(blockchain: blockchain)
                .resolve(for: link)
        case .blink:
            return BlinkAPIResolver(keysConfig: keysConfig)
                .resolve(for: blockchain)
        case .nowNodes:
            return NowNodesAPIResolver(apiKey: keysConfig.nowNodesApiKey)
                .resolve(for: blockchain)
        case .quickNode:
            return QuickNodeAPIResolver(keysConfig: keysConfig)
                .resolve(for: blockchain)
        case .getBlock:
            return GetBlockAPIResolver(credentials: keysConfig.getBlockCredentials)
                .resolve(for: blockchain)
        case .infura:
            return InfuraAPIResolver(keysConfig: keysConfig)
                .resolve(for: blockchain)
        case .ton:
            return TONAPIResolver(keysConfig: keysConfig)
                .resolve(blockchain: blockchain)
        case .tron:
            return TronAPIResolver(keysConfig: keysConfig)
                .resolve(blockchain: blockchain)
        case .adalite, .tangemRosetta:
            return CardanoAPIResolver()
                .resolve(providerType: providerType, blockchain: blockchain)
        case .tangemChia, .fireAcademy, .tangemChia3:
            return ChiaAPIResolver(keysConfig: keysConfig)
                .resolve(providerType: providerType, blockchain: blockchain)
        case .arkhiaHedera:
            return HederaAPIResolver(keysConfig: keysConfig)
                .resolve(providerType: providerType, blockchain: blockchain)
        case .kaspa:
            return KaspaAPIResolver(keysConfig: keysConfig)
                .resolve(blockchain: blockchain)
        case .onfinality:
            return OnfinalityAPIResolver(keysConfig: keysConfig)
                .resolve()
        case .dwellir:
            return DwellirAPIResolver(keysConfig: keysConfig)
                .resolve(for: blockchain)
        case .koinosPro:
            return KoinosAPIResolver(keysConfig: keysConfig)
                .resolve(blockchain: blockchain)
        case .tangemAlephium:
            return AlephiumAPIResolver(keysConfig: keysConfig)
                .resolve(providerType: .tangemAlephium, blockchain: blockchain)
        case .blockchair, .blockcypher, .solana:
            return nil
        case .tatum:
            return TatumAPIResolver(keysConfig: keysConfig)
                .resolve(providerType: providerType, blockchain: blockchain)
        case .mock:
            return MockAPIResolver()
                .resolve(providerType: providerType, blockchain: blockchain)
        }
    }
}
