//
//  PepecoinTestnetNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

/// Data is taken from:
/// https://github.com/pepecoinppc/pepecoin/blob/4fb5a0cd930c0df82c88292e973a7b7cfa06c4e8/src/chainparams.cpp
final class PepecoinTestnetNetworkParams: INetwork {
    /// base58Prefixes[PUBKEY_ADDRESS]
    let pubKeyHash: UInt8 = 0x71

    /// base58Prefixes[SECRET_KEY]
    let privateKey: UInt8 = 0xf1

    /// base58Prefixes[SCRIPT_ADDRESS]
    let scriptHash: UInt8 = 0xc4

    /// bech32_hrp
    let bech32PrefixPattern: String = "P"

    /// base58Prefixes[EXT_PUBLIC_KEY]
    let xPubKey: UInt32 = 0x043587CF

    /// base58Prefixes[EXT_SECRET_KEY]
    let xPrivKey: UInt32 = 0x04358394

    let magic: UInt32 = 0xC0C0C0C0

    /// nDefaultPort
    let port: UInt32 = 44874

    /// DNS seeds are not specified in C++ code
    let dnsSeeds: [String] = []

    let dustRelayTxFee: Int = 1_000_000 // 0.01 PEPE

    let coinType: UInt32 = 1

    /// Assuming the standard "ALL" for SigHash type
    let sigHash: SigHashType = .bitcoinAll

    let syncableFromApi: Bool = true
}

// MARK: - UTXONetworkParams

extension PepecoinTestnetNetworkParams: UTXONetworkParams {
    var p2pkhPrefix: UInt8 { pubKeyHash }
    var p2shPrefix: UInt8 { scriptHash }
    var bech32Prefix: String { bech32PrefixPattern }
}
