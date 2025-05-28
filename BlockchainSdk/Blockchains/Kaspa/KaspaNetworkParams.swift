//
//  KaspaNetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct KaspaNetworkParams: UTXONetworkParams {
    /// Version(0) - Schnorr
    /// Version(1) - ECDSA
    let p2pkhPrefix: UInt8 = 0x01
    let p2shPrefix: UInt8 = 0x08
    let bech32Prefix: String = "kaspa"
    let dustRelayTxFee: Int = 3000
    let coinType: UInt32 = 111111
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
}

struct KaspaTestNetworkParams: UTXONetworkParams {
    let p2pkhPrefix: UInt8 = 0x01
    let p2shPrefix: UInt8 = 0x08
    let bech32Prefix: String = "kaspatest"
    let dustRelayTxFee: Int = 3000
    let coinType: UInt32 = 111111
    let signHashType: UTXONetworkParamsSignHashType = .bitcoinAll
}
