//
//  RadiantNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// https://github.com/RadiantBlockchain/radiant-node/blob/3bfd3ed2ed535b7d3058cbeecc2caa5be8f1115f/src/chainparams.cpp#L193
struct RadiantNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x00
    let p2shPrefix: UInt8 = 0x05
    let bech32Prefix: String = "radaddr"
    let coinType: UInt32 = 512
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = .radiant
}
