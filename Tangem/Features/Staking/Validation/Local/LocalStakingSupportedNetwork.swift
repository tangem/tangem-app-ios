//
//  LocalStakingSupportedNetwork.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum LocalStakingSupportedNetwork {
    case tron
    case solana
    case cosmos
    case bsc
    case cardano

    init?(blockchain: Blockchain) {
        switch blockchain {
        case .tron: self = .tron
        case .solana: self = .solana
        case .cosmos: self = .cosmos
        case .bsc: self = .bsc
        case .cardano: self = .cardano
        default: return nil
        }
    }
}
