//
//  BitcoinNetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BitcoinCore

struct BitcoinNetworkParams: UTXONetworkParams {
    let p2pkh: UInt8 = 0x00
    let p2sh: UInt8 = 0x05
    let bech32: String = "bc"
}

struct BitcoinTestnetNetworkParams: UTXONetworkParams {
    let p2pkh: UInt8 = 0x6f
    let p2sh: UInt8 = 0xc4
    let bech32: String = "tb"
}
