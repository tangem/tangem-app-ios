//
//  LitecoinNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct LitecoinNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x30
    let p2shPrefix: UInt8 = 0x32
    let bech32Prefix: String = "ltc"
    let coinType: UInt32 = 2
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = .litecoin
}
