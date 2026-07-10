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
    private let batchBalancesService: P2PBatchBalancesService
    private let yieldInfoProvider: StakingYieldInfoProvider
    private let analyticsLogger: StakingAnalyticsLogger
    private let stateRepository: StakingManagerStateRepository
    private let isRegionUnavailableHandlingEnabled: Bool

    private let _state: CurrentValueSubject<StakingManagerState, Never>
    private var previousFee: Decimal?

    init(
        integrationId: String,
        wallet: StakingWallet,
        apiProvider: P2PAPIProvider,
        batchBalancesService: P2PBatchBalancesService,
        yieldInfoProvider: StakingYieldInfoProvider,
        stateRepository: StakingManagerStateRepository,
        analyticsLogger: StakingAnalyticsLogger,
        isRegionUnavailableHandlingEnabled: Bool
    ) {
        self.integrationId = integrationId
        self.wallet = wallet
        self.apiProvider = apiProvider
        self.batchBalancesService = batchBalancesService
        self.yieldInfoProvider = yieldInfoProvider
        self.stateRepository = stateRepository
        self.analyticsLogger = analyticsLogger
        self.isRegionUnavailableHandlingEnabled = isRegionUnavailableHandlingEnabled

        _state = CurrentValueSubject(.loading(cached: stateRepository.state()))
    }
}

// MARK: - StakingManager

extension P2PStakingManager: StakingManager {
    func updateState(loadActions: Bool, source: StakingUpdateSource) async {
        updateState(.loading(cached: stateRepository.state()))

        do {
            let yield = try await yieldInfoProvider.yieldInfo(for: integrationId)

            guard !yield.targets.isEmpty else {
                // Empty vaults should show as temporarily unavailable, not disabled
                updateState(.temporaryUnavailable(yield, cached: stateRepository.state()))
                return
            }

            let balances: [StakingBalanceInfo]
            switch source {
            case .batch:
                let allBalances = try await batchBalancesService.balances()
                balances = allBalances[wallet.address.lowercased()] ?? []
            case .single:
                do {
                    balances = try await apiProvider.balances(
                        walletAddress: wallet.address,
                        vaults: yield.targets.map(\.address)
                    )
                } catch is CancellationError {
                    return
                } catch let error where isRegionUnavailableHandlingEnabled && error.isStakingRegionUnavailable {
                    updateRegionUnavailableState()
                    return
                } catch {
                    updateUnavailableState(error: error, yieldIsAvailable: yield.isAvailable)
                    return
                }
            }

            let state = state(balances: balances, yield: yield)
            updateState(state)
        } catch is CancellationError {
            // Ignored intentionally
            return
        } catch let error where isRegionUnavailableHandlingEnabled && error.isStakingRegionUnavailable {
            updateRegionUnavailableState()
        } catch let error as StakingAvailabilityError {
            updateUnavailableState(error: error, yieldIsAvailable: false)
        } catch {
            updateState(.loadingError(error.localizedDescription, cached: stateRepository.state()))
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

        let baseline = previousFee ?? .zero
        previousFee = newTransaction.fee

        if newTransaction.fee > baseline {
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
        stateRepository.storeState(state)
        _state.send(state)
    }

    func updateRegionUnavailableState() {
        let cached = stateRepository.state()

        switch cached?.stakeState {
        case .staked:
            updateState(.unavailableInRegion(cached: cached))
        case .availableToStake, .none:
            updateState(.notEnabled)
        }
    }

    func updateUnavailableState(error: Error, yieldIsAvailable: Bool) {
        let cached = stateRepository.state()

        let shouldHide: Bool
        switch cached?.stakeState {
        case .staked:
            shouldHide = false
        case .availableToStake, .none:
            shouldHide = !yieldIsAvailable
        }

        if shouldHide {
            updateState(.notEnabled)
        } else {
            updateState(.loadingError(error.localizedDescription, cached: cached))
        }
    }

    func state(balances: [StakingBalanceInfo]?, yield: StakingYieldInfo?) -> StakingManagerState {
        guard let yield else {
            return .notEnabled
        }

        let stakingBalances = balances?.map { balance in
            mapToStakingBalance(balance: balance, yield: yield)
        }

        // Preserve .staked UI for users with existing positions even when no vault accepts new stakes.
        if let stakingBalances, !stakingBalances.isEmpty {
            return .staked(.init(balances: stakingBalances, yieldInfo: yield, canStakeMore: yield.isAvailable))
        }

        guard !yield.preferredTargets.isEmpty else {
            return .notEnabled
        }

        guard yield.isAvailable else {
            return .temporaryUnavailable(yield, cached: stateRepository.state())
        }

        return .availableToStake(yield)
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
