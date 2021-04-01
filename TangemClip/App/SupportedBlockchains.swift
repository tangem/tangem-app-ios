//
//  SupportedBlockchains.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdkClips
import BlockchainSdkClips

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
                .tezos(curve: .secp256k1)
            ]
        case .ed25519:
            return [
                .cardano(shelley: true)
            ]
        default:
            return []
        }
    }
}
