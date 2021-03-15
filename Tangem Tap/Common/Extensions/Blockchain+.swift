//
//  Blockchain+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Blockchain: Identifiable {
    public var id: Int { return hashValue }
    
    var imageName: String? {
        switch self {
        case .binance:
            return "binance"
        case .bitcoin:
            return "btc"
        case .bitcoinCash:
            return "btc_cash"
        case .cardano:
            return "cardano"
        case .ethereum:
            return "eth"
        case .litecoin:
            return "litecoin"
        case .rsk:
            return "rsk"
        case .tezos:
            return "tezos"
        case .xrp:
            return "xrp"
        default:
            return nil
        }
    }
}
