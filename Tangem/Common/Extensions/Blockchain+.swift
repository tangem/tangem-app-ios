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
    
    var iconName: String? {
        switch self {
        case .avalanche: return "avalanche"
        case .binance: return "binance"
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bch"
        case .bsc: return "bsc"
        case .cardano: return "cardano"
        case .dogecoin: return "doge"
        case .ducatus: return nil
        case .ethereum: return "ethereum"
        case .fantom: return "fantom"
        case .kusama: return nil
        case .litecoin: return "litecoin"
        case .polkadot: return nil
        case .polygon: return "polygon"
        case .rsk: return "rsk"
        case .solana: return "solana"
        case .stellar: return "stellar"
        case .tezos: return "tezos"
        case .xrp: return "xrp"
        }
    }
    
    var iconNameFilled: String? {
        iconName.map { "\($0).fill" }
    }
    
    var contractName: String? {
        switch self {
        case .binance: return "BEP2"
        case .bsc: return "BEP20"
        case .ethereum: return "ERC20"
        default:
            return nil
        }
    }
}
