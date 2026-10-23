//
//  DashMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// You can find this constants in the class `CMainParams` from
/// /// https://github.com/dashpay/dash/blob/master/src/chainparams.cpp#L327
struct DashMainNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x4c
    let p2shPrefix: UInt8 = 0x10
    /// Don't used in this network
    let bech32Prefix: String = "bc"

    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll

    let dustCalculator: UTXONetworkParamsDustCalculator = .dashMainnet
}
