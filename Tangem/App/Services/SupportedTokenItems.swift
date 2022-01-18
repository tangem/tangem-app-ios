//
//  SupportedTokenItems.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import struct BlockchainSdk.Token
import enum BlockchainSdk.Blockchain
#endif
import TangemSdk

class SupportedTokenItems {
    lazy var predefinedBlockchains: Set<Blockchain> = {
        [
            .ethereum(testnet: false),
            .bitcoin(testnet: false),
        ]
    }()
    
    private let sources: [Blockchain: String] = [
        .ethereum(testnet: false) : "ethereumTokens",
        .ethereum(testnet: true) : "ethereumTokens_testnet",
        .binance(testnet: false) : "binanceTokens",
        .binance(testnet: true) : "binanceTokens_testnet",
        .bsc(testnet: false) : "binanceSmartChainTokens",
        .bsc(testnet: true) : "binanceSmartChainTokens_tesnet",
        .polygon(testnet: false) : "polygonTokens",
        .avalanche(testnet: false) : "avalanchecTokens"
    ]
    
    private lazy var blockchains: Set<Blockchain> = {
        [
            .ethereum(testnet: false),
            .litecoin,
            .bitcoin(testnet: false),
            .bitcoinCash(testnet: false),
            .xrp(curve: .secp256k1),
            .rsk,
            .binance(testnet: false),
            .tezos(curve: .secp256k1),
            .stellar(testnet: false),
            .cardano(shelley: true),
            .dogecoin,
            .bsc(testnet: false),
            .polygon(testnet: false),
            .avalanche(testnet: false)
        ]
    }()
    
    private lazy var testnetBlockchains: Set<Blockchain> = {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true),
            .avalanche(testnet: true)
        ]
    }()
    
    func blockchains(for curves: [EllipticCurve], isTestnet: Bool) -> Set<Blockchain> {
        let allBlockchains = isTestnet ? testnetBlockchains : blockchains
        return allBlockchains.filter { curves.contains($0.curve) }
    }
    
    func tokens(for blockchain: Blockchain) -> [Token] {
        guard let src = sources[blockchain] else {
            return []
        }
        
        return (try? JsonUtils.readBundleFile(with: src,
                                              type: [Token].self,
                                              shouldAddCompilationCondition: false)) ?? []
    }
}
