//
//  P2PStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class P2PStakingManager {
    private let wallet: StakingWallet
    private let provider: P2PAPIProvider
    private let analyticsLogger: StakingAnalyticsLogger

    private let _state = CurrentValueSubject<StakingManagerState, Never>(.loading)
    private var pendingTransaction: StakingTransactionInfo?

    init(wallet: StakingWallet, provider: P2PAPIProvider, analyticsLogger: StakingAnalyticsLogger) {
        self.wallet = wallet
        self.provider = provider
        self.analyticsLogger = analyticsLogger
    }
}

extension P2PStakingManager: StakingManager {
    func updateState(loadActions: Bool) async {
        _state.send(.loading)

        let yield = try? await provider.yield()

        guard let yield, !yield.preferredValidators.isEmpty else {
            _state.send(.notEnabled)
            return
        }

        let balances = try? await provider.balances(
            walletAddress: wallet.address,
            vaults: yield.validators.map(\.address)
        )
        let state = state(balances: balances, yield: yield)
        _state.send(state)
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    var state: StakingManagerState {
        _state.value
    }

    var balances: [StakingBalance]? {
        []
    }

    var allowanceAddress: String? {
        nil
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        guard let validatorAddress = action.validatorInfo?.address else {
            throw P2PStakingAPIError.invalidVault
        }
        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            return try await estimateFee(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            let transactionInfo = try await provider.stakeTransaction(
                walletAddress: wallet.address,
                vault: validatorAddress,
                amount: action.amount
            )
            pendingTransaction = transactionInfo
            return transactionInfo.fee
        case (.staked, .unstake):
            fatalError()
        case (.staked, .pending(let type)):
            fatalError()
        default:
            StakingLogger.info(self, "Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportEstimateFeeAction(action: action, state: state)
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        guard let pendingTransaction else {
            throw P2PStakingAPIError.transactionNotFound
        }
        return StakingTransactionAction(amount: action.amount, transactions: [pendingTransaction])
    }

    func transactionDetails(id: String) async throws -> StakingTransactionInfo {
        fatalError()
    }

    func transactionDidSent(action: StakingAction) {}
}

extension P2PStakingManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["item": wallet.item])
    }
}

private extension P2PStakingManager {
    func state(balances: [StakingBalanceInfo]?, yield: StakingYieldInfo?) -> StakingManagerState {
        guard let yield, !yield.preferredValidators.isEmpty else {
            return .notEnabled
        }

        guard yield.isAvailable else {
            return .temporaryUnavailable(yield)
        }

        let stakingBalances = balances?.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        guard let stakingBalances, !stakingBalances.isEmpty else {
            return .availableToStake(yield)
        }

        return .staked(.init(balances: stakingBalances, yieldInfo: yield, canStakeMore: false))
    }
}
