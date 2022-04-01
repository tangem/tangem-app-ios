//
//  Blockchain+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Blockchain {
    var id: String {
        switch self {
        case .binance: return "binancecoin"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoinCash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "ripple"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binance-smart-chain"
        case .polygon: return "matic-network" //[REDACTED_TODO_COMMENT]
        case .avalanche: return "avalanche-2"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        }
    }
    
    private static var testnetId = "/test"
    
    var rawStringId: String {
        var name = "\(self)".lowercased()
        
        if let index = name.firstIndex(of: "(") {
            name = String(name.prefix(upTo: index))
        }
        
        return name
    }
    
    var stringId: String {
        let name = rawStringId
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
