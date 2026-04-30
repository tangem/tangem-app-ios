//
//  DogecoinNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct DogecoinNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x1E
    let p2shPrefix: UInt8 = 0x16
    let bech32Prefix: String = "D"
    let coinType: UInt32 = 3
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustRelayTxFee: Int = 1_000_000 // 0.01 DOGE
}
