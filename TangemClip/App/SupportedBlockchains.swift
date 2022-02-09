//
//  SupportedBlockchains.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

enum SupportedBlockchains {
    static func blockchains(from curve: EllipticCurve, testnet: Bool) -> [Blockchain] {
        switch curve {
        case .secp256k1:
            return [
                .bitcoin(testnet: testnet),
                .ethereum(testnet: testnet),
                .litecoin,
                .bitcoinCash(testnet: testnet),
                .xrp(curve: .secp256k1),
                .rsk,
                .tezos(curve: .secp256k1),
                .binance(testnet: testnet),
                .bsc(testnet: testnet),
                .dogecoin,
                .polygon(testnet: testnet)
            ]
        case .ed25519:
            return [
                .stellar(testnet: testnet),
                .cardano(shelley: true),
                .solana(testnet: testnet),
                .polkadot(testnet: testnet),
                .kusama,
            ]
        default:
            return []
        }
    }
}
