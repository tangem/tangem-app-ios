//
//  CardType.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
#if !CLIP
import BlockchainSdk
#endif

enum TangemNote: String, CaseIterable {
    /// AB01
    case btc = "AB01"
    /// AB02
    case eth = "AB02"
    /// AB03
    case ada = "AB03"
    /// AB04
    case dogecoin = "AB04"
    /// AB05
    case bnb = "AB05"
    /// AB06
    case xrp = "AB06"
    
    static func isNoteBatch(_ batch: String) -> Bool {
        TangemNote(rawValue: batch.uppercased()) != nil
    }
    
    var curve: EllipticCurve {
        switch self {
        case .ada: return .ed25519
        default: return .secp256k1
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .btc: return .bitcoin(testnet: false)
        case .eth: return .ethereum(testnet: false)
        case .ada: return .cardano(shelley: true)
        case .dogecoin: return .dogecoin
        case .bnb: return .binance(testnet: false)
        case .xrp: return .xrp(curve: curve)
        }
    }
}
