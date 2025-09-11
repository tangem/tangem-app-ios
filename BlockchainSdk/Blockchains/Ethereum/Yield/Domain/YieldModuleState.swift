//
//  YieldModuleState.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

public enum YieldModuleState {
    case notDeployed
    case deployed(DeployedState)

    public struct DeployedState {
        public let yieldModule: String
        public let initializationState: InitializationState

        public init(yieldModule: String, initializationState: InitializationState) {
            self.yieldModule = yieldModule
            self.initializationState = initializationState
        }
    }

    public enum InitializationState {
        case notInitialized
        case initialized(activeState: ActiveState)
    }

    public enum ActiveState {
        case notActive
        case active(info: ActiveStateInfo)
    }
    
    public struct ActiveStateInfo {
        let balance: BigUInt
        let maxNetworkFee: BigUInt
    }

    public var yieldModule: String? {
        switch self {
        case .notDeployed: nil
        case .deployed(let deployedState): deployedState.yieldModule
        }
    }

    public var isActive: Bool {
        switch self {
        case .notDeployed:
            return false
        case .deployed(let deployedState):
            if case .initialized(.active) = deployedState.initializationState {
                return true
            } else {
                return false
            }
        }
    }
}
