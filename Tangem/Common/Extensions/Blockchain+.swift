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
        case .bitcoinCash: return "bitcoin-cash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereum-classic"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "ripple"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binancecoin"
        case .polygon: return "matic-network"
        case .avalanche: return "avalanche-2"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum-one"
        case .dash: return "dash"
        }
    }
    
    var currencyId: String {
        switch self {
        case .arbitrum(let testnet):
            return Blockchain.ethereum(testnet: testnet).id
        default:
            return id
        }
    }
    
    var networkId: String {
        switch self {
        case .binance: return "binancecoin"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoin-cash"
        case .cardano: return "cardano"
        case .ducatus: return "ducatus"
        case .ethereum: return "ethereum"
        case .ethereumClassic: return "ethereum-classic"
        case .litecoin: return "litecoin"
        case .rsk: return "rootstock"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "xrp"
        case .dogecoin: return "dogecoin"
        case .bsc: return "binance-smart-chain"
        case .polygon: return "polygon-pos"
        case .avalanche: return "avalanche"
        case .solana: return "solana"
        case .fantom: return "fantom"
        case .polkadot: return "polkadot"
        case .kusama: return "kusama"
        case .tron: return "tron"
        case .arbitrum: return "arbitrum-one"
        case .dash: return "dash"
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

    // Init blockchain from id with default params
    init?(from stringId: String) {
        let isTestnet = stringId.contains(Blockchain.testnetId)
        let rawId = stringId.remove(Blockchain.testnetId)
        switch rawId {
        case "bitcoin": self = .bitcoin(testnet: isTestnet)
        case "stellar": self = .stellar(testnet: isTestnet)
        case "ethereum": self = .ethereum(testnet: isTestnet)
        case "ethereum-classic": self = .ethereumClassic(testnet: isTestnet)
        case "litecoin": self = .litecoin
        case "rootstock": self = .rsk
        case "bitcoin-cash": self = .bitcoinCash(testnet: isTestnet)
        case "binancecoin": self = .binance(testnet: isTestnet)
        case "cardano": self = .cardano(shelley: true)
        case "ripple", "xrp": self = .xrp(curve: .secp256k1)
        case "ducatus": self = .ducatus
        case "tezos": self = .tezos(curve: .secp256k1)
        case "dogecoin": self = .dogecoin
        case "binance-smart-chain": self = .bsc(testnet: isTestnet)
        case "polygon-pos", "matic-network": self = .polygon(testnet: isTestnet)
        case "avalanche", "avalanche-2": self = .avalanche(testnet: isTestnet)
        case "solana": self = .solana(testnet: isTestnet)
        case "fantom": self = .fantom(testnet: isTestnet)
        case "polkadot": self = .polkadot(testnet: isTestnet)
        case "kusama": self = .kusama
        case "tron": self = .tron(testnet: isTestnet)
        case "arbitrum", "arbitrum-one": self = .arbitrum(testnet: isTestnet)
        case "dash": self = .dash(testnet: isTestnet)
        default:
            print("⚠️⚠️⚠️ Failed to map network ID \"\(stringId)\"")
            return nil
        }
    }
    
    var iconName: String {
        let rawId = rawStringId
        
        if rawId == "binance" {
            return "bsc"
        }
        
        return rawId
    }
    
    var iconNameFilled: String { "\(iconName).fill" }
}
