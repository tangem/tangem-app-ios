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
    public enum State {
        case notInitialized(yieldToken: String?)
        case initialized(state: ActiveState, maxNetworkFee: BigUInt)
    }

    public enum ActiveState {
        case notActive
        case active(BigUInt?)
    }

    public var balances: BigUInt? {
        switch state {
        case .initialized(.active(let balances), _): balances
        default: nil
        }
    }

    public let state: State
}
