//
//  StakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingManager {
    var state: StakingManagerState { get }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { get }

    func updateState() async throws
    func transaction(action: StakingActionType) async throws -> StakingTransactionInfo
}

public enum StakingActionType {
    case stake(amount: Decimal, validator: String)
    case claimRewards
    case unstake(validator: String)
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading
    case notEnabled
    case availableToStake(YieldInfo)
    case staked([StakingBalanceInfo], YieldInfo)

    public var isAvailable: Bool {
        switch self {
        case .loading, .notEnabled:
            return false
        case .availableToStake, .staked:
            return true
        }
    }

    public var isStaked: Bool {
        switch self {
        case .staked: true
        default: false
        }
    }

    public var yieldInfo: YieldInfo? {
        switch self {
        case .loading, .notEnabled:
            return nil
        case .availableToStake(let yieldInfo),
             .staked(_, let yieldInfo):
            return yieldInfo
        }
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .availableToStake: "availableToStake"
        case .staked: "staked"
        }
    }
}
