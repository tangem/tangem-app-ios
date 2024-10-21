//
//  RadiantUnspentOutput.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantUnspentOutput {
    let amount: UInt64
    let outputIndex: Int
    let hash: Data
    let outputScript: Data
}
