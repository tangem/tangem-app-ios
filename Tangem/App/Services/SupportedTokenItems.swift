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
    lazy var predefinedDemoBalances: [Blockchain: Decimal] = {
        [
            .bitcoin(testnet: false): 0.005,
            .ethereum(testnet: false): 0.12,
            .dogecoin: 45,
            .solana(testnet: false): 3.246,
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
        .polygon(testnet: true) : "polygonTestnet",
        .avalanche(testnet: false) : "avalanche",
        .avalanche(testnet: true) : "avalancheTestnet",
        .solana(testnet: false): "solana",
        .solana(testnet: true): "solanaTestnet", // Solana devnet
        .fantom(testnet: false): "fantom",
        .fantom(testnet: true): "fantomTestnet",
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
//            .polkadot(testnet: false),
//            .kusama,
            .fantom(testnet: false),
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
            .fantom(testnet: true),
           // .polkadot(testnet: true),
        ]
    }()
    
    func predefinedBlockchains(isDemo: Bool) -> [Blockchain] {
        if isDemo {
            return Array(predefinedDemoBalances.keys)
        }
        
        return [.ethereum(testnet: false), .bitcoin(testnet: false)]
    }
    
    func blockchains(for curves: [EllipticCurve], isTestnet: Bool?) -> Set<Blockchain> {
        let allBlockchains = isTestnet.map { $0 ? testnetBlockchains : blockchains }
        ?? testnetBlockchains.union(blockchains)
        return allBlockchains.filter { curves.contains($0.curve) }
    }
    
    func hasTokens(for blockchain: Blockchain) -> Bool {
        sources[blockchain] != nil
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
                      customIconUrl: $0.customIconUrl,
                      blockchain: blockchain)
            }
        } catch {
            Log.error(error.localizedDescription)
            return []
        }
    }
}
