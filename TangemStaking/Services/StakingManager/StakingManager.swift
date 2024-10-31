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
    var allowanceAddress: String? { get }

    func updateState() async
    func estimateFee(action: StakingAction) async throws -> Decimal
    func transaction(action: StakingAction) async throws -> StakingTransactionAction

    func transactionDidSent(action: StakingAction)
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading
    case notEnabled
    case loadingError(String)
    // When we turn off the YieldInfo in the admin panel
    case temporaryUnavailable(YieldInfo)
    case availableToStake(YieldInfo)
    case staked(Staked)

    public var yieldInfo: YieldInfo? {
        switch self {
        case .loading, .notEnabled, .loadingError:
            return nil
        case .temporaryUnavailable(let yieldInfo), .availableToStake(let yieldInfo):
            return yieldInfo
        case .staked(let staked):
            return staked.yieldInfo
        }
    }

    public var balances: [StakingBalance]? {
        guard case .staked(let stakeInfo) = self else {
            return nil
        }

        return stakeInfo.balances
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .loadingError(let error): "loadingError \(error)"
        case .temporaryUnavailable: "temporaryUnavailable"
        case .availableToStake: "availableToStake"
        case .staked: "staked"
        }
    }
}

public extension StakingManagerState {
    struct Staked: Hashable {
        public let balances: [StakingBalance]
        public let yieldInfo: YieldInfo
        public let canStakeMore: Bool
    }
}
