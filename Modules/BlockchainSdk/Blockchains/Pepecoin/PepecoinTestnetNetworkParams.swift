//
//  PepecoinTestnetNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct PepecoinTestnetNetworkParams: UTXONetworkParams {
    /// base58Prefixes[PUBKEY_ADDRESS]
    let p2pkhPrefix: UInt8 = 0x71

    /// base58Prefixes[SCRIPT_ADDRESS]
    let p2shPrefix: UInt8 = 0xc4

    let bech32Prefix: String = "P"
    let coinType: UInt32 = 1
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = .pepecoin
}
