//
//  Fact0rnMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct Fact0rnMainNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x00
    let p2shPrefix: UInt8 = 0x05
    let bech32Prefix: String = "fact"
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll

    let coinType: UInt32 = 42069

    let dustCalculator: UTXONetworkParamsDustCalculator = .fact0rn
}
