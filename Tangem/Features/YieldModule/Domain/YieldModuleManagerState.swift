//
//  YieldModuleManagerState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum YieldModuleManagerState: Equatable {
    case disabled
    case loading
    case notActive
    case processing(action: ProcessingAction)
    case active(YieldSupplyInfo)
    case failedToLoad(error: String)

    var balance: Amount? {
        if case .active(let value) = self {
            return value.balance
        }
        return nil
    }

    enum ProcessingAction {
        case enter
        case exit
    }
}

struct YieldModuleManagerStateInfo: Equatable {
    let marketInfo: YieldModuleMarketInfo?

    let state: YieldModuleManagerState
}
