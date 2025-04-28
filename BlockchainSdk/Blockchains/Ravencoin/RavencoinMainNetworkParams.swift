//
//  RavencoinMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// You can find this constants in the class `CMainParams` from
/// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp
struct RavencoinMainNetworkParams: UTXONetworkParams {
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L195
    /// base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,60);
    /// Decimal(60) = UInt8(0x3C)
    let p2pkhPrefix: UInt8 = 0x3C

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L196
    /// base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,122);
    /// Decimal(122) = UInt8(0x7A)
    let p2shPrefix: UInt8 = 0x7A

    /// Don't use in this network
    let bech32Prefix: String = "bc"

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L202
    /// Raven BIP44 cointype in mainnet is '175'
    /// nExtCoinType = 175;
    let coinType: UInt32 = 175
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
    /// https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L44
    /// static const unsigned int DUST_RELAY_TX_FEE = 3000;
    let dustRelayTxFee = 3000

    let publicKeyType: UTXONetworkParamsPublicKeyType = .asIs
}
