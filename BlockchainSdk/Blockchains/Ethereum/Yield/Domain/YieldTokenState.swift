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
    case deployed(DeployedState)

    public struct DeployedState {
        public let yieldToken: String
        public let initializationState: InitializationState

        public init(yieldToken: String, initializationState: InitializationState) {
            self.yieldToken = yieldToken
            self.initializationState = initializationState
        }
    }

    public enum InitializationState {
        case notInitialized
        case initialized(activeState: ActiveState)
    }

    public enum ActiveState {
        case notActive
        case active(maxNetworkFee: BigUInt)
    }
}
