//
//  BitcoinScript.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BitcoinScript {
    let chunks: [BitcoinScriptChunk]
    let data: Data
}
