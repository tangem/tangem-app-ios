//
//  StakingManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
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

    func transactionDidSent(action: StakingAction)
}

public extension StakingManager {
    func updateState() async {
        await updateState(loadActions: false)
    }

    func waitForLoadingCompletion() async throws {
        // Drop the current `loading` state
        _ = try await statePublisher.dropFirst().first().async()
        // Check if after the loading state we have same status
        // To exclude endless recursion
        if case .loading = state {
            throw StakingManagerError.stakingManagerIsLoading
        }
    }

    func mapToStakingBalance(balance: StakingBalanceInfo, yield: StakingYieldInfo) -> StakingBalance {
        let targetType: StakingTargetType = {
            guard let targetAddress = balance.targetAddress else {
                return .empty
            }

            let target = yield.targets.first(where: { $0.address == targetAddress })
            return target.map { .target($0) } ?? .disabled
        }()

        return StakingBalance(
            item: balance.item,
            amount: balance.amount,
            accountAddress: balance.accountAddress,
            balanceType: balance.balanceType,
            targetType: targetType,
            inProgress: false,
            actions: balance.actions,
            actionConstraints: balance.actionConstraints
        )
    }
}
