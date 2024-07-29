//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class CommonStakingManager {
    private let integrationId: String
    private let wallet: StakingWallet
    private let provider: StakingAPIProvider
    private let logger: Logger

    // MARK: Private

    private let _state = CurrentValueSubject<StakingManagerState, Never>(.loading)

    init(
        integrationId: String,
        wallet: StakingWallet,
        provider: StakingAPIProvider,
        logger: Logger
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.provider = provider
        self.logger = logger
    }
}

// MARK: - StakingManager

extension CommonStakingManager: StakingManager {
    var state: StakingManagerState {
        _state.value
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    func updateState() async throws {
        updateState(.loading)
        do {
            async let balance = provider.balance(wallet: wallet)
            async let yield = provider.yield(integrationId: integrationId)

            try await updateState(state(balance: balance, yield: yield))
        } catch {
            logger.error(error)
            throw error
        }
    }

    func transaction(action: StakingActionType) async throws -> StakingTransactionInfo {
        switch (state, action) {
        case (.availableToStake(let yieldInfo), .stake(let amount, let validator)):
            try await getTransactionToStake(amount: amount, validator: validator, integrationId: yieldInfo.id)
        case (.staked(_, _), .unstake):
            throw StakingManagerError.notImplemented // [REDACTED_TODO_COMMENT]
        default:
            throw StakingManagerError.stakingManagerStateNotSupportTransactionAction(action: action)
        }
    }
}

// MARK: - Private

private extension CommonStakingManager {
    func updateState(_ state: StakingManagerState) {
        log("Update state to \(state)")
        _state.send(state)
    }

    func state(balance: StakingBalanceInfo?, yield: YieldInfo) -> StakingManagerState {
        guard let balance else {
            return .availableToStake(yield)
        }

        if balance.balanceGroupType.isActiveOrUnstaked {
            return .staked(balance, yield)
        } else {
            return .availableToStake(yield)
        }
    }

    func getTransactionToStake(amount: Decimal, validator: String, integrationId: String) async throws -> StakingTransactionInfo {
        let action = try await provider.enterAction(
            amount: amount,
            address: wallet.address,
            validator: validator,
            integrationId: integrationId
        )

        let transactionId = action.transactions[action.currentStepIndex].id
        // We have to wait that stakek.it prepared the transaction
        // Otherwise we may get the 404 error
        try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        let transaction = try await provider.patchTransaction(id: transactionId)

        return transaction
    }
}

// MARK: - Log

private extension CommonStakingManager {
    func log(_ args: Any) {
        logger.debug("[Staking] \(self) \(args)")
    }
}

public enum StakingManagerError: Error {
    case stakingManagerStateNotSupportTransactionAction(action: StakingActionType)
    case notImplemented
    case notFound
}
