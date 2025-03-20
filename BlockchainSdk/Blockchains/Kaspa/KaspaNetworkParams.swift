//
//  KaspaNetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct KaspaNetworkParams: UTXONetworkParams {
    var p2sh: UInt8 { 0x00 }
    var p2pkh: UInt8 { 0x08 }
    var bech32: String { "kaspa" }
}
