//
//  StakingFlowStages.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

/// The shared, network-agnostic staking flow primitives. Holds only what every flow needs and the
/// happy path that ties them together. Chain-specific enter-prerequisites (Ethereum's ERC-20 approval,
/// Cardano's minimum-amount rule) live in the providers that use them, with their own dependencies —
/// not here.
struct StakingFlowStages {
    let stakingManager: StakingManager
    let transactionValidator: SendTransactionValidator
    let feeIncludedCalculator: FeeIncludedCalculator
    let accountInitializationService: BlockchainAccountInitializationService?
    let minimalBalanceProvider: MinimalBalanceProvider?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem

    init(
        stakingManager: StakingManager,
        transactionValidator: SendTransactionValidator,
        feeIncludedCalculator: FeeIncludedCalculator,
        accountInitializationService: BlockchainAccountInitializationService?,
        minimalBalanceProvider: MinimalBalanceProvider? = nil,
        tokenItem: TokenItem,
        feeTokenItem: TokenItem
    ) {
        self.stakingManager = stakingManager
        self.transactionValidator = transactionValidator
        self.feeIncludedCalculator = feeIncludedCalculator
        self.accountInitializationService = accountInitializationService
        self.minimalBalanceProvider = minimalBalanceProvider
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func estimateFee(action: StakingAction) async throws -> Decimal {
        try await stakingManager.estimateFee(action: action)
    }

    func accountInit(transactionFee: Decimal) async throws -> StakeFlowState? {
        guard let accountInitializationService,
              try await accountInitializationService.isAccountInitialized() == false else {
            return nil
        }

        let initializationFee = try await accountInitializationService.estimateInitializationFee()
        return .prerequisite(.accountInitialization(.required(initializationFee: initializationFee, transactionFee: makeFee(transactionFee))))
    }

    /// The shared happy path used by every network: estimate the fee, surface a pending
    /// account-initialization if the (optional) service reports one, otherwise finalize.
    func resolveCommon(action: StakingAction, stepPlan: StakeStepPlan) async throws -> StakeFlowState {
        let fee = try await estimateFee(action: action)

        if let state = try await accountInit(transactionFee: fee) {
            return state
        }

        let state = finalize(
            amount: action.amount,
            fee: fee,
            target: action.targetInfo,
            isAmountEditable: stepPlan.amount.isEditable,
            includesStakesCount: stepPlan.includesStakesCount,
            isEnter: action.type.isEnter
        )

        // Entering a position (stake) surfaces extra "max" / different-validator hints on the ready state.
        guard action.type.isEnter, case .ready(let ready) = state else {
            return state
        }

        return .ready(enterExtras(ready: ready, fee: fee, target: action.targetInfo))
    }

    /// Enter-only ready extras: how much to free up for a "max" stake when the fee is included, and
    /// whether the position already stakes on a different validator (driving a "stakes will move" notice).
    private func enterExtras(ready: StakeFlowState.Ready, fee: Decimal, target: StakingTargetInfo?) -> StakeFlowState.Ready {
        let stakeOnDifferentValidator = (stakingManager.balances ?? []).contains { balance in
            balance.balanceType == .active && balance.targetType.target != target
        }

        let amountToReduce: Decimal? = ready.isFeeIncluded
            ? fee * Constants.reduceAmountMultiplier + (minimalBalanceProvider?.minimalBalance() ?? .zero)
            : nil

        return StakeFlowState.Ready(
            amount: ready.amount,
            fee: ready.fee,
            isFeeIncluded: ready.isFeeIncluded,
            stakesCount: ready.stakesCount,
            amountToReduce: amountToReduce,
            stakeOnDifferentValidator: stakeOnDifferentValidator
        )
    }

    func finalize(amount: Decimal, fee: Decimal, target: StakingTargetInfo?, isAmountEditable: Bool, includesStakesCount: Bool, isEnter: Bool) -> StakeFlowState {
        let spendsWallet = isAmountEditable && isEnter
        let includeFee = spendsWallet
            && feeIncludedCalculator.shouldIncludeFee(makeFee(fee), into: makeAmount(amount))
        let resolvedAmount = includeFee ? amount - fee : amount

        if let validationError = validate(amount: spendsWallet ? resolvedAmount : .zero, fee: fee) {
            return validationError
        }

        let stakesCount = includesStakesCount
            ? target.flatMap { stakingManager.state.stakesCount(for: $0) }
            : nil

        return .ready(.init(amount: resolvedAmount, fee: fee, isFeeIncluded: includeFee, stakesCount: stakesCount))
    }

    /// Surfaces a transaction validation failure, or `nil` when the amount+fee are spendable. Exposed
    /// so a chain-specific pre-stage (e.g. Ethereum's approve) can validate fee coverage without
    /// re-deriving amounts.
    func validate(amount: Decimal, fee: Decimal) -> StakeFlowState? {
        do {
            try transactionValidator.validate(amount: makeAmount(amount), fee: makeFee(fee))
            return nil
        } catch let error as ValidationError {
            return .failure(.transaction(error, fee: fee))
        } catch CardanoError.feeParametersNotFound {
            return nil
        } catch {
            return .failure(.network(error))
        }
    }

    // MARK: - Helpers

    private func makeAmount(_ value: Decimal) -> Amount {
        Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: value)
    }

    private func makeFee(_ value: Decimal) -> Fee {
        Fee(Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: value))
    }

    private enum Constants {
        static let reduceAmountMultiplier: Decimal = 3
    }
}

enum StakeModelError: Error {
    case revokeAndApproveNotSupported
    case accountIsNotInitialized
    case notReady
    case networkNotSupported
}
