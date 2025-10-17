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
    // total balance: yield module + non yield
    let balance: Amount
    let isAllowancePermissionRequired: Bool
    /// yield module only balance
    let yieldModuleBalanceValue: Decimal

    /// non yield module balance
    /// after balance top up, funds are not deposited immediately
    /// there can be significant lag due to network conditions (hi fees etc.)
    var nonYieldModuleBalanceValue: Decimal {
        balance.value - yieldModuleBalanceValue
    }
}
