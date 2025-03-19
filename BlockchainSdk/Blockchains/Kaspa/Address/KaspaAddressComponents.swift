//
//  KaspaAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

struct KaspaAddressComponents {
    let prefix: String
    let type: KaspaAddressType
    let hash: Data
}

extension KaspaAddressComponents {
    enum KaspaAddressType: UInt8 {
        case P2PK_Schnorr = 0
        case P2PK_ECDSA = 1
        case P2SH = 8
    }
}

struct KaspaNetworkParams: UTXONetworkParams {
    var p2pkh: UInt8 { 0x00 }
    var p2sh: UInt8 { 0x08 }
    var bech32: String { "kaspa" }
}
