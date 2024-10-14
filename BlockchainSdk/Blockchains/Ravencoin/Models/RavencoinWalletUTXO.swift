//
//  RavencoinWalletUTXO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct RavencoinWalletUTXO: Decodable {
    let txid: String
    let vout: Int
    let satoshis: UInt64
    let scriptPubKey: String
}
