//
//  BitcoinCashNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinCashNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x00
    let p2shPrefix: UInt8 = 0x05
    let bech32Prefix: String = "bitcoincash"
    let coinType: UInt32 = 145
    let dustRelayTxFee = 3000 // https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinCashAll
}

struct BitcoinCashTestNetworkParams: UTXONetworkParams {
    /// https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/blob/master/src/chainparams.cpp?ref_type=heads#L462
    let p2pkhPrefix: UInt8 = 0x6f

    /// https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/blob/master/src/chainparams.cpp?ref_type=heads#L463
    let p2shPrefix: UInt8 = 0xc4

    /// https://gitlab.com/bitcoin-cash-node/bitcoin-cash-node/-/blob/master/src/chainparams.cpp?ref_type=heads#L467
    let bech32Prefix: String = "bchtest"
    let coinType: UInt32 = 1
    let dustRelayTxFee = 1000 // https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinCashAll
}
