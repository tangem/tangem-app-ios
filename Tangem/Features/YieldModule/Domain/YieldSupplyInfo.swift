//
//  YieldSupplyInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct YieldSupplyInfo: Equatable {
    let yieldContractAddress: String
    let balance: Amount
    let allowance: Decimal
}
