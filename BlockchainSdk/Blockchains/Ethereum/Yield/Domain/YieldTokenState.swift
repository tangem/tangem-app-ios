//
//  YieldTokenState.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum YieldTokenState {
    case notDeployed
    case notInitialized(yieldToken: String)
    case initialized(activeState: ActiveState)

    public enum ActiveState {
        case notActive
        case active(ActiveStateInfo)
    }

    public struct ActiveStateInfo {
        public let yieldToken: String
        public let maxNetworkFee: BigUInt
    }
}
