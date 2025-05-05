//
//  PepecoinMainnetNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Data is taken from:
/// https://github.com/pepecoinppc/pepecoin/blob/4fb5a0cd930c0df82c88292e973a7b7cfa06c4e8/src/chainparams.cpp
struct PepecoinMainnetNetworkParams: UTXONetworkParams {
    /// base58Prefixes[PUBKEY_ADDRESS]
    let p2pkhPrefix: UInt8 = 0x38

    /// base58Prefixes[SCRIPT_ADDRESS]
    let p2shPrefix: UInt8 = 0x16
    let bech32Prefix: String = "P"
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let coinType: UInt32 = 3434
    let dustRelayTxFee: Int = 1_000_000 // 0.01 PEPE
    let publicKeyType: UTXONetworkParamsPublicKeyType = .compressed
}
