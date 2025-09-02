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
        case .initialized(.active(let balances), _): balances
        default: nil
        }
    }

    public var hasActiveYield: Bool {
        balances?.protocol != nil && balances?.protocol != 0
    }
}

public extension YieldBalanceInfo {
    enum State {
        case notInitialized(yieldToken: String?)
        case initialized(state: ActiveState, maxNetworkFee: BigUInt)
    }

    enum ActiveState {
        case notActive
        case active(YieldBalances?)
    }
}
