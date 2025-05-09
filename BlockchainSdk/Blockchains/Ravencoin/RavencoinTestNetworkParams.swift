//
//  RavencoinTestNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// You can find this constants in the class `CTestNetParams` from
/// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp
struct RavencoinTestNetworkParams: UTXONetworkParams {
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L421
    /// base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,111);
    /// Decimal(111) = UInt8(0x6F)
    let p2pkhPrefix: UInt8 = 0x6F

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L422
    /// base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,196);
    /// Decimal(196) = UInt8(0xC4)
    let p2shPrefix: UInt8 = 0xC4

    /// Don't use in this network
    let bech32Prefix: String = "bc"

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L428
    /// Raven BIP44 cointype in testnet
    /// nExtCoinType = 1;
    let coinType: UInt32 = 1

    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/policy/policy.h#L48
    /// static const unsigned int DUST_RELAY_TX_FEE = 3000;
    let dustRelayTxFee = 3000

    let publicKeyType: UTXONetworkParamsPublicKeyType = .asIs
}
