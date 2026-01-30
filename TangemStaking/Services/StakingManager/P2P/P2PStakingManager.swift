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
    private let integrationId: String
    private let wallet: StakingWallet
    private let apiProvider: P2PAPIProvider
    private let yieldInfoProvider: StakingYieldInfoProvider
    private let analyticsLogger: StakingAnalyticsLogger
    private let stateRepository: StakingManagerStateRepository

    private let _state: CurrentValueSubject<StakingManagerState, Never>
    private var previousFee: Decimal?

    init(
        integrationId: String,
        wallet: StakingWallet,
        apiProvider: P2PAPIProvider,
        yieldInfoProvider: StakingYieldInfoProvider,
        stateRepository: StakingManagerStateRepository,
        analyticsLogger: StakingAnalyticsLogger
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.yieldInfoProvider = yieldInfoProvider
        self.stateRepository = stateRepository
        self.analyticsLogger = analyticsLogger

        _state = CurrentValueSubject(.loading(cached: stateRepository.state(cacheId: wallet.cacheId)))
    }
}

// MARK: - StakingManager

extension P2PStakingManager: StakingManager {
    func updateState(loadActions: Bool) async {
        updateState(.loading(cached: stateRepository.state(cacheId: wallet.cacheId)))

        do {
            let yield = try await yieldInfoProvider.yieldInfo(for: integrationId)

            guard !yield.preferredTargets.isEmpty else {
                // Empty vaults should show as temporarily unavailable, not disabled
                updateState(.temporaryUnavailable(yield, cached: stateRepository.state(cacheId: wallet.cacheId)))
                return
            }

            let balances = try await apiProvider.balances(
                walletAddress: wallet.address,
                vaults: yield.preferredTargets.map(\.address)
            )
            let state = state(balances: balances, yield: yield)
            updateState(state)
        } catch {
            updateState(.loadingError(error.localizedDescription, cached: stateRepository.state(cacheId: wallet.cacheId)))
        }
    }

    var statePublisher: AnyPublisher<StakingManagerState, Never> {
        _state.eraseToAnyPublisher()
    }

    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
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

    var tosURL: URL { URL(string: "https://www.p2p.org/terms-of-use/")! }
    var privacyPolicyURL: URL { URL(string: "https://www.p2p.org/privacy-policy/")! }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        do {
            let transaction = try await transactionInfo(action: action)
            previousFee = transaction.fee
            return transaction.fee
        } catch {
            previousFee = nil
            throw error
        }
    }

    func transaction(action: StakingAction) async throws -> StakingTransactionAction {
        let newTransaction = try await transactionInfo(action: action)

        if newTransaction.fee > previousFee ?? .zero {
            throw P2PStakingError.feeIncreased(newFee: newTransaction.fee)
        }

        return StakingTransactionAction(amount: action.amount, transactions: [newTransaction])
    }

    func transactionDidSent(action: StakingAction) {
        previousFee = nil

        Task { @MainActor [weak self] in
            await self?.updateState()
        }
    }
}

extension P2PStakingManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: ["item": wallet.item])
    }
}

private extension P2PStakingManager {
    func updateState(_ state: StakingManagerState) {
        stateRepository.storeState(state, cacheId: wallet.cacheId)
        _state.send(state)
    }

    func state(balances: [StakingBalanceInfo]?, yield: StakingYieldInfo?) -> StakingManagerState {
        guard let yield else {
            return .notEnabled
        }

        // Empty validators or unavailable yield means temporarily unavailable
        guard !yield.preferredTargets.isEmpty, yield.isAvailable else {
            return .temporaryUnavailable(yield, cached: stateRepository.state(cacheId: wallet.cacheId))
        }

        let stakingBalances = balances?.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        guard let stakingBalances, !stakingBalances.isEmpty else {
            return .availableToStake(yield)
        }

        return .staked(.init(balances: stakingBalances, yieldInfo: yield, canStakeMore: true))
    }

    func transactionInfo(action: StakingAction) async throws -> StakingTransactionInfo {
        guard let vaultAddress = action.targetInfo?.address else {
            throw P2PStakingError.invalidVault
        }

        let result: StakingTransactionInfo

        switch (state, action.type) {
        case (.loading, _):
            try await waitForLoadingCompletion()
            result = try await transactionInfo(action: action)
        case (.availableToStake, .stake), (.staked, .stake):
            result = try await apiProvider.stakeTransaction(
                walletAddress: wallet.address,
                vault: vaultAddress,
                amount: action.amount
            )
        case (.staked, .unstake):
            result = try await apiProvider.unstakeTransaction(
                walletAddress: wallet.address,
                vault: vaultAddress,
                amount: action.amount
            )
        case (.staked, .pending):
            result = try await apiProvider.withdrawTransaction(
                walletAddress: wallet.address,
                vault: vaultAddress,
                amount: action.amount
            )
        default:
            StakingLogger.info(self, "Invalid staking manager state: \(state), for action: \(action)")
            throw StakingManagerError.stakingManagerStateNotSupportEstimateFeeAction(action: action, state: state)
        }

        return result
    }
}
