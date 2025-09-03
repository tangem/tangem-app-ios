//
//  YieldBalanceInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public struct YieldBalanceInfo {
    public let state: State

    public var balances: YieldBalances? {
        switch state {
        case .initialized(.active(let activeStateInfo)): activeStateInfo.balances
        default: nil
        }
    }
}

public extension YieldBalanceInfo {
    enum State {
        case notDeployed
        case notInitialized(yieldToken: String)
        case initialized(activeState: ActiveState)
    }

    enum ActiveState {
        case notActive
        case active(ActiveStateInfo)
    }

    struct ActiveStateInfo {
        public let yieldToken: String
        public let maxNetworkFee: BigUInt
        public let balances: YieldBalances?

        public var hasActiveYield: Bool {
            balances?.protocol != nil && balances?.protocol != 0
        }
    }
}
