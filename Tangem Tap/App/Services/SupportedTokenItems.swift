//
//  SupportedTokenItems.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

class SupportedTokenItems {
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
            .bsc(testnet: false)
        ]
    }()
    
    private lazy var testnetBlockchains: Set<Blockchain> = {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .matic(testnet: true)
        ]
    }()
    
    lazy var erc20Tokens: [Token] = {
        let tokens = try? JsonUtils.readBundleFile(with: "erc20tokens",
                                                   type: [Token].self,
                                                   shouldAddCompilationCondition: false)
        
        return tokens ?? []
    }()
    
    lazy var erc20TokensTestnet: [Token] = {
        let tokens = try? JsonUtils.readBundleFile(with: "erc20tokens_testnet",
                                                 type: [Token].self,
                                                 shouldAddCompilationCondition: false)
      
      return tokens ?? []
    }()
    
    lazy var binanceSmartChainTokens: [Token] = {
       []
    }()
    
    var binanceSmartChainTokensTestnet: [Token] {
        let tokens = try? JsonUtils.readBundleFile(with: "binanceSmartChainTokens_testnet",
                                                   type: [Token].self,
                                                   shouldAddCompilationCondition: false)
        
        return tokens ?? []
    }
    
    func blockchains(for card: Card) -> Set<Blockchain> {
        var availableBlockchains = Set<Blockchain>()
        
        for curve in card.walletCurves {
            let blockchains = card.isTestnet ? testnetBlockchains : blockchains
            blockchains.filter { $0.curve == curve }.forEach {
                availableBlockchains.insert($0)
            }
        }
        
        return availableBlockchains
    }
}
