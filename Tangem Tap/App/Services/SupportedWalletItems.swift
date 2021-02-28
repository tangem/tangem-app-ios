//
//  SupportedWalletItems.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

class SupportedWalletItems {
    lazy var blockchains: Set<Blockchain> = {[.ethereum(testnet: false),
                                              .litecoin,
                                              .bitcoin(testnet: false),
                                              .bitcoinCash(testnet: false),
                                              .xrp(curve: .secp256k1),
                                              .rsk,
                                              .binance(testnet: false),
                                              .tezos]}()
    
    lazy var erc20Tokens: [Token] = {
        let tokens = try? JsonUtils.readBundleFile(with: "erc20tokens",
                                                   type: [Token].self,
                                                   shouldAddCompilationCondition: false)
        
        return tokens ?? []
    }()
}
