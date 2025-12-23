//
//  YieldModuleManagerState.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemMacro

@CaseFlagable
indirect enum YieldModuleManagerState: Equatable {
    case disabled
    case loading(cachedState: YieldModuleManagerState?)
    case notActive
    case processing(action: ProcessingAction)
    case active(YieldSupplyInfo)
    case failedToLoad(error: String, cachedState: YieldModuleManagerState?)

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

extension YieldModuleManagerStateInfo {
    static let empty = YieldModuleManagerStateInfo(marketInfo: nil, state: .notActive)
}

extension YieldModuleManagerState {
    var isEffectivelyActive: Bool {
        switch self {
        case .active:
            true
        case .failedToLoad(_, let cached?), .loading(let cached?):
            cached.isEffectivelyActive
        default:
            false
        }
    }

    var cachedState: YieldModuleManagerState? {
        switch self {
        case .failedToLoad(_, let cached), .loading(let cached):
            return cached

        default:
            return nil
        }
    }

    var activeInfo: YieldSupplyInfo? {
        switch self {
        case .active(let info):
            return info
        case .failedToLoad(_, let cached?):
            return cached.activeInfo
        default:
            return nil
        }
    }

    var isBusy: Bool {
        switch self {
        case .loading, .processing:
            return true
        default:
            return false
        }
    }
}
