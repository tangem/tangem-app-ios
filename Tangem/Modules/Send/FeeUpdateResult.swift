//
//  FeeUpdateResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct FeeUpdateResult {
    let oldFee: Amount?
    let newFee: Amount
}
