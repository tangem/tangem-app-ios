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
        .ethereum(testnet: false) : "ethereum",
        .ethereum(testnet: true) : "ethereumTestnet",
        .binance(testnet: false) : "binance",
        .binance(testnet: true) : "binanceTestnet",
        .bsc(testnet: false) : "bsc",
        .bsc(testnet: true) : "bscTestnet",
        .polygon(testnet: false) : "polygon",
        .avalanche(testnet: false) : "avalanche",
        .avalanche(testnet: true) : "avalancheTestnet",
        .solana(testnet: false): "solana",
        .solana(testnet: true): "solanaDevnet",
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
            .avalanche(testnet: false),
            .solana(testnet: false),
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
            .avalanche(testnet: true),
            .solana(testnet: true),
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
        
        do {
            let tokens = try JsonUtils.readBundleFile(with: src,
                                                      type: [TokenDTO].self,
                                                      shouldAddCompilationCondition: false)
            return tokens.map {
                Token(name: $0.name,
                      symbol: $0.symbol,
                      contractAddress: $0.contractAddress,
                      decimalCount: $0.decimalCount,
                      customIcon: $0.customIcon,
                      customIconUrl: $0.customIconUrl,
                      blockchain: blockchain)
            }
        } catch {
            Log.error(error.localizedDescription)
            return []
        }
    }
}
