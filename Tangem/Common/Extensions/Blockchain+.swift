//
//  Blockchain+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
#if !CLIP
import BlockchainSdk
#endif

extension Blockchain: Identifiable {
    public var id: Int { return hashValue }
    
    private static var testnetId = "/test"
    
    var rawStringId: String {
        var name = "\(self)".lowercased()
        
        if let index = name.firstIndex(of: "(") {
            name = String(name.prefix(upTo: index))
        }
        
        return name
    }
    
    var stringId: String {
        var name = rawStringId
        return isTestnet ? "\(name)\(Blockchain.testnetId)" : name
    }
    //bitcoinCash, bsc, avalanche
    //Init blockchain from id with default params
    init?(from stringId: String) {
        let isTestnet = stringId.contains(Blockchain.testnetId)
        let rawId = stringId.remove(Blockchain.testnetId)
        switch rawId {
        case "bitcoin": self = .bitcoin(testnet: isTestnet)
        case "stellar": self = .stellar(testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rsk", "rootstock": self = .rsk
        case "bitcoincash": self = .bitcoinCash(testnet: isTestnet)
        case "binance", "binancecoin": self = .binance(testnet: isTestnet)
        case "cardano": self = .cardano(shelley: true)
        case "xrp", "ripple": self = .xrp(curve: .secp256k1)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: .secp256k1)
        case "dogecoin": self = .dogecoin
        case "bsc", "binance-smart-chain": self = .bsc(testnet: isTestnet)
        case "polygon", "polygon-pos", "matic-network": self = .polygon(testnet: isTestnet)
        case "avalanche", "avalanche-2": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(testnet: isTestnet)
        case "kusama": self = .kusama
        default: return nil
        }
    }
    
    var iconName: String { rawStringId }
    
    var iconNameFilled: String { "\(iconName).fill" }
}
