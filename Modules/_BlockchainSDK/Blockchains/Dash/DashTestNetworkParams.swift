//
//  DashTestNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// You can find this constants in the class `CMainParams` from
/// /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L535
struct DashTestNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x8c
    let p2shPrefix: UInt8 = 0x13
    // Don't use in this network
    let bech32Prefix: String = "bc"
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let coinType: UInt32 = 1

    /// https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L36
    let dustRelayTxFee = 1000
}
