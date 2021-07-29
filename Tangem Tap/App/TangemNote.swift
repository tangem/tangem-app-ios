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
    case ab01 = "AB01", ab02 = "AB02", ab03 = "AB03", ab04 = "AB04", ab05 = "AB05", ab06 = "AB06"
    
    static func isNoteBatch(_ batch: String) -> Bool {
        TangemNote(rawValue: batch) != nil
    }
    
    var curve: EllipticCurve {
        switch self {
        case .ab03: return .ed25519
        default: return .secp256k1
        }
    }
    
    var blockchain: Blockchain {
        switch self {
        case .ab01: return .bitcoin(testnet: false)
        case .ab02: return .ethereum(testnet: false)
        case .ab03: return .cardano(shelley: true)
        case .ab04: return .dogecoin
        case .ab05: return .binance(testnet: false)
        case .ab06: return .xrp(curve: curve)
        }
    }
}
