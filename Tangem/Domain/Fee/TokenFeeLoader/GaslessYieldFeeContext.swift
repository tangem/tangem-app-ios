//
//  GaslessYieldFeeContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

struct GaslessYieldFeeContext {
    let yieldContractAddress: String
    let yieldModuleBalance: Decimal
    let feeTokenBalanceProvider: TokenBalanceProvider
    let versionChecker: YieldModuleVersionChecker?
}

extension GaslessYieldFeeContext: CustomStringConvertible {
    var description: String {
        objectDescription("GaslessYieldFeeContext", userInfo: [
            "yieldContractAddress": yieldContractAddress,
            "yieldModuleBalance": yieldModuleBalance,
            "feeTokenBalanceProvider": feeTokenBalanceProvider,
            "versionChecker": String(describing: versionChecker),
        ])
    }
}
