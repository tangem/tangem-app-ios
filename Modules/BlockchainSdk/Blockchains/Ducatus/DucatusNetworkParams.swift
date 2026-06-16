//
//  DucatusNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct DucatusNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x31
    let p2shPrefix: UInt8 = 0x33
    let bech32Prefix: String = "duc"
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let coinType: UInt32 = 0
    let dustCalculator: UTXONetworkParamsDustCalculator = .ducatus
}
