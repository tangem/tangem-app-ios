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
    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> { get }

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

    func mapToStakingBalance(balance: StakingBalanceInfo, yield: StakingYieldInfo) -> StakingBalance {
        let validatorType: StakingValidatorType = {
            guard let validatorAddress = balance.validatorAddress else {
                return .empty
            }

            let validator = yield.validators.first(where: { $0.address == validatorAddress })
            return validator.map { .validator($0) } ?? .disabled
        }()

        return StakingBalance(
            item: balance.item,
            amount: balance.amount,
            accountAddress: balance.accountAddress,
            balanceType: balance.balanceType,
            validatorType: validatorType,
            inProgress: false,
            actions: balance.actions,
            actionConstraints: balance.actionConstraints
        )
    }
}
