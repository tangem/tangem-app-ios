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
    var p2pkhPrefix: UInt8 { 0x01 }
    var p2shPrefix: UInt8 { 0x08 }
    var bech32Prefix: String { "kaspa" }
    var dustRelayTxFee: Int { 3000 }
}

struct KaspaTestNetworkParams: UTXONetworkParams {
    var p2pkhPrefix: UInt8 { 0x01 }
    var p2shPrefix: UInt8 { 0x08 }
    var bech32Prefix: String { "kaspatest" }
    var dustRelayTxFee: Int { 3000 }
}
