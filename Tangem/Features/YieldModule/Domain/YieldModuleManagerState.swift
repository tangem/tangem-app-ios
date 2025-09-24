//
//  YieldModuleManagerState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum YieldModuleManagerState {
    case disabled
    case loading
    case notActive(apy: Decimal?)
    case active(YieldModuleManagerStateInfo)
    case failedToLoad(error: String)

    var balance: Amount? {
        if case .active(let value) = self {
            return value.amount
        }
        return nil
    }
}

struct YieldModuleManagerStateInfo {
    let marketInfo: YieldModuleMarketInfo?
    let amount: Amount?

    var tokenYieldSupply: TokenYieldSupply? {
        amount?.tokenYieldSupply
    }
}

private extension Amount {
    var tokenYieldSupply: TokenYieldSupply? {
        guard case .token(let token) = type else { return nil }
        return token.metadata.kind.supplyInfo
    }
}
