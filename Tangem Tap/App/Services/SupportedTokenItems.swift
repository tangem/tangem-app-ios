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
            .bsc(testnet: false),
            .polygon(testnet: false)
        ]
    }()
    
    private lazy var testnetBlockchains: Set<Blockchain> = {
        [
            .bitcoin(testnet: true),
            .ethereum(testnet: true),
            .binance(testnet: true),
            .stellar(testnet: true),
            .bsc(testnet: true),
            .polygon(testnet: true)
        ]
    }()
    
    lazy var ethereumTokens: [Token] = {
        tokens(fromFile: "ethereumTokens", for: .ethereum(testnet: false), shouldSortByName: true, shouldPrintJson: true)
    }()
    
    lazy var ethereumTokensTestnet: [Token] = {
        tokens(fromFile: "ethereumTokens_testnet", for: .ethereum(testnet: true))
    }()
    
    lazy var binanceSmartChainTokens: [Token] = {
        tokens(fromFile: "binanceSmartChainTokens", for: .bsc(testnet: false), shouldSortByName: true)
    }()
    
    var binanceSmartChainTokensTestnet: [Token] {
        tokens(fromFile: "binanceSmartChainTokens_testnet", for: .bsc(testnet: true))
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
    
    private func tokens(fromFile fileName: String, for blockchain: Blockchain, shouldSortByName: Bool = false, shouldPrintJson: Bool = true) -> [Token] {
        var tokens = try? JsonUtils.readBundleFile(with: fileName,
                                                   type: [Token].self,
                                                   shouldAddCompilationCondition: false)
        if shouldSortByName {
            tokens?.sort(by: { $0.name < $1.name && $0.symbol < $1.symbol })
        }
        
        if shouldPrintJson, let tokens = tokens {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let json = String(data: try! encoder.encode(tokens), encoding: .utf8)
            print(json!)
        }
        
        return tokens ?? []
    }
}
