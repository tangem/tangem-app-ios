//
//  Alephium+NetworkId.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension ALPH {
    enum NetworkId: UInt8 {
        case mainnet = 0
        case testnet = 1

        static var serde: ALPH.AnySerde<ALPH.NetworkId> {
            ALPH.ByteSerde().xmap(to: { NetworkId(rawValue: $0) ?? .mainnet }, from: { $0.rawValue })
        }
    }
}
