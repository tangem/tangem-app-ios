//
//  BitcoinNetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x00
    let p2shPrefix: UInt8 = 0x05
    let bech32Prefix: String = "bc"
    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    let coinType: UInt32 = 0
    var publicKeyType: UTXONetworkParamsPublicKeyType = .compressed
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
}

struct BitcoinTestnetNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x6f
    let p2shPrefix: UInt8 = 0xc4
    let bech32Prefix: String = "tb"
    let dustRelayTxFee = 3000 //  https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    let coinType: UInt32 = 0
    var publicKeyType: UTXONetworkParamsPublicKeyType = .compressed
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
}
