//
//  TangemTokenEntity.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

#if !CLIP
import BlockchainSdk
#endif

struct TangemTokenEntity: Codable {
    public let id: String
    public let name: String
    public let symbol: String
    public let contracts: [ContractEntity]?
}

extension TangemTokenEntity {
    struct ContractEntity: Codable {
        public let networkId: NetworkId
        public let address: String
        public let decimalCount: Int
    }
}

extension TangemTokenEntity {
    enum NetworkId: String, Codable {
        case polygon = "polygon-pos"
        case solana
        case binance = "binancecoin"
        case bsc = "binance-smart-chain"
        case ethereum
        case avalanche
        case fantom
        
        var blockchain: Blockchain? {
            Blockchain.from(blockchainName: blockchainName, curve: curve)
        }
        
        private var blockchainName: String {
            switch self {
            case .polygon:
                return "polygon"
            case .binance:
                return "binance"
            case .bsc:
                return "bsc"
            case .ethereum:
                return "eth"
            default:
                return rawValue
            }
        }
        
        private var curve: EllipticCurve {
            switch self {
            case .polygon, .binance, .bsc, .ethereum, .avalanche, .fantom:
                return .secp256k1
            case  .solana:
                return .ed25519
            }
        }
    }
}
