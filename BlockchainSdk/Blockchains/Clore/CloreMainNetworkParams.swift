//
//  CloreMainNetworkParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BitcoinCore

/// You can find this constants in the class `CMainParams` from
/// https://gitlab.com/cloreai-public/blockchain
///
/// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp
class CloreMainNetworkParams: INetwork {
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L195
    /// base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1,60);
    /// Decimal(23) = UInt8(0x17)
    let pubKeyHash: UInt8 = 0x17

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L196
    /// base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1,122);
    /// Decimal(122) = UInt8(0x7a)
    let scriptHash: UInt8 = 0x7a

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L197
    /// base58Prefixes[SECRET_KEY] =     std::vector<unsigned char>(1,128);
    /// Decimal(128) = UInt8(0x80)
    let privateKey: UInt8 = 0x80

    let bech32PrefixPattern: String = "bc"

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L198
    /// base58Prefixes[EXT_PUBLIC_KEY] = {0x04, 0x88, 0xB2, 0x1E};
    let xPubKey: UInt32 = 0x0488b21e

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L199
    /// base58Prefixes[EXT_SECRET_KEY] = {0x04, 0x88, 0xAD, 0xE4};
    let xPrivKey: UInt32 = 0x0488ade4

    /// Protocol message header bytes
    /// https://github.com/RavenProject/Ravencoin/blob/master/src/chainparams.cpp#L177
    /// pchMessageStart[0] = 0x52; // R
    /// pchMessageStart[1] = 0x41; // A
    /// pchMessageStart[2] = 0x56; // V
    /// pchMessageStart[3] = 0x4e; // N
    let magic: UInt32 = 0x5241564e

    /// https://gitlab.com/cloreai-public/blockchain/-/blob/main/src/chainparams.cpp?ref_type=heads#L184
    /// nDefaultPort = 8788;
    let port: UInt32 = 8788

    /// CLORE Blockchain BIP44 cointype in mainnet is '1313'
    /// nExtCoinType = 1313;
    let coinType: UInt32 = 1313

    let sigHash: SigHashType = .bitcoinAll

    /// https://gitlab.com/cloreai-public/blockchain/-/blob/main/src/chainparams.cpp?ref_type=heads#L184
    let dnsSeeds = [
        "seed.clore.ai",
        "seed1.clore.ai",
        "seed2.clore.ai",
    ]

    /// https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L44
    /// static const unsigned int DUST_RELAY_TX_FEE = 3000;
    let dustRelayTxFee = 3000
    init() {}
}

extension CloreMainNetworkParams: UTXONetworkParams {
    var p2pkhPrefix: UInt8 { pubKeyHash }
    var p2shPrefix: UInt8 { scriptHash }
    var bech32Prefix: String { bech32PrefixPattern }
}
