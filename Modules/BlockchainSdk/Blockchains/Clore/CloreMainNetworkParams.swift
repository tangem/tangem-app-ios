//
//  CloreMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// You can find this constants in the class `CMainParams` from
/// https://gitlab.com/cloreai-public/blockchain
/// https://gitlab.com/cloreai-public/blockchain/-/blob/main/src/chainparams.cpp
struct CloreMainNetworkParams: UTXONetworkParams {
    /// base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,60);
    /// Decimal(23) = UInt8(0x17)
    let p2pkhPrefix: UInt8 = 0x17

    /// base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,122);
    /// Decimal(122) = UInt8(0x7a)
    let p2shPrefix: UInt8 = 0x7a

    /// Don't use in this network
    let bech32Prefix: String = "bc"

    /// https://gitlab.com/cloreai-public/blockchain/-/blob/main/src/chainparams.cpp#L196
    let coinType: UInt32 = 1313

    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    let dustCalculator: UTXONetworkParamsDustCalculator = BitcoinUTXONetworkParamsDustCalculator(dustRelayTxFee: 3000)
}
