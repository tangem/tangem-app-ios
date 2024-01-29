//
//  FeeUpdateResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum FeeUpdateResult: Error {
    case success(oldFee: Amount?, newFee: Amount)
    case failedToGetFee
}
