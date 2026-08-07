//
//  BitcoinNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x00
    let p2shPrefix: UInt8 = 0x05
    let bech32Prefix: String = "bc"
    let coinType: UInt32 = 0
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = .bitcoinMainnet
}

struct BitcoinTestnetNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x6f
    let p2shPrefix: UInt8 = 0xc4
    let bech32Prefix: String = "tb"
    let coinType: UInt32 = 0
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = .bitcoinTestnet
}
