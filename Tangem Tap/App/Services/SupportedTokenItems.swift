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
    private lazy var blockchains: Set<Blockchain> = {[.ethereum(testnet: false),
                                              .litecoin,
                                              .bitcoin(testnet: false),
                                              .bitcoinCash(testnet: false),
                                              .xrp(curve: .secp256k1),
                                              .rsk,
                                              .binance(testnet: false),
                                              .tezos(curve: .secp256k1),
                                              .stellar(testnet: false),
                                              .cardano(shelley: true)]
    }()
    
    func blockchains(for card: Card) -> Set<Blockchain> {
        var availableBlockchains = Set<Blockchain>()
        
        for curve in card.walletCurves {
            blockchains.filter { $0.curve == curve }.forEach {
                availableBlockchains.insert($0)
            }
        }
        
        return availableBlockchains
    }
    
    lazy var erc20Tokens: [Token] = {
        let tokens = try? JsonUtils.readBundleFile(with: "erc20tokens",
                                                   type: [Token].self,
                                                   shouldAddCompilationCondition: false)
        
        return tokens ?? []
    }()
}
