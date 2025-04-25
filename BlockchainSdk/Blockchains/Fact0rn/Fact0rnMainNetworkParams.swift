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

    /// https://github.com/FACT0RN/FACT0RN/blob/d02b33f3d5ce8a4be57fdb8c8b0bc3cb51760116/src/policy/policy.h#L54
    let dustRelayTxFee: Int = 3000

    let publicKeyType: UTXONetworkParamsPublicKeyType = .compressed
}
