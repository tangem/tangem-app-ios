//
//  AptosFeeParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct AptosFeeParams: FeeParameters {
    let gasUnitPrice: UInt64
    let maxGasAmount: UInt64
}
