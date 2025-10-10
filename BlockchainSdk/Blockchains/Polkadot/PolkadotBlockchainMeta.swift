//
//  PolkadotBlockchainMeta.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct PolkadotBlockchainMeta {
    let specVersion: UInt32
    let transactionVersion: UInt32
    let genesisHash: String
    let blockHash: String
    let nonce: UInt32
    let era: Era

    struct Era {
        let blockNumber: UInt64
        let period: UInt64
    }
}
