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
    var balances: [StakingBalance]? { get }

    var statePublisher: AnyPublisher<StakingManagerState, Never> { get }
    var allowanceAddress: String? { get }

    func updateState(loadActions: Bool) async
    func estimateFee(action: StakingAction) async throws -> Decimal
    func transaction(action: StakingAction) async throws -> StakingTransactionAction
    func transactionDetails(id: String) async throws -> StakingTransactionInfo

    func transactionDidSent(action: StakingAction)
}

public extension StakingManager {
    func updateState() async {
        await updateState(loadActions: false)
    }
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading
    case notEnabled
    case loadingError(String)
    // When we turn off the YieldInfo in the admin panel
    case temporaryUnavailable(StakingYieldInfo)
    case availableToStake(StakingYieldInfo)
    case staked(Staked)

    public var yieldInfo: StakingYieldInfo? {
        switch self {
        case .loading, .notEnabled, .loadingError:
            return nil
        case .temporaryUnavailable(let yieldInfo), .availableToStake(let yieldInfo):
            return yieldInfo
        case .staked(let staked):
            return staked.yieldInfo
        }
    }

    public var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    public var isSuccessfullyLoaded: Bool {
        switch self {
        case .staked, .availableToStake:
            return true
        default:
            return false
        }
    }

    public func stakesCount(for validator: ValidatorInfo) -> Int? {
        switch self {
        case .staked(let staked):
            staked.balances.filter { $0.validatorType.validator?.address == validator.address }.count
        default: nil
        }
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
        public let yieldInfo: StakingYieldInfo
        public let canStakeMore: Bool
    }
}
