//
//  PsbtScriptPubKeyType.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum PsbtScriptPubKeyType {
    case p2pkh
    case p2wpkh
    case unsupported(String)

    init(scriptPubKey: Data) {
        // p2wpkh: 0x00 0x14 <20>
        if scriptPubKey.count == 22, scriptPubKey[0] == 0x00, scriptPubKey[1] == 0x14 {
            self = .p2wpkh
            return
        }

        // p2pkh: 76 a9 14 <20> 88 ac
        if scriptPubKey.count == 25,
           scriptPubKey[0] == 0x76,
           scriptPubKey[1] == 0xA9,
           scriptPubKey[2] == 0x14,
           scriptPubKey[23] == 0x88,
           scriptPubKey[24] == 0xAC {
            self = .p2pkh
            return
        }

        self = .unsupported("Unsupported scriptPubKey (len=\(scriptPubKey.count))")
    }
}
