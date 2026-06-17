//
//  EthereumStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

/// Ethereum StakeKit staking (e.g. Polygon/MATIC via the Ethereum network). Editable stake amount,
/// validator selection, partial unstake — and an ERC-20 approval prerequisite before entering a position.
///
/// The approval is this chain's specialness, so the allowance state machine and its collaborators
/// (`allowanceService`, `tokenFeeProvidersManager`) live here rather than in the shared stages.
struct EthereumStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages
    let allowanceService: AllowanceService?
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }

    private var approvePolicy: ApprovePolicy { .specified }

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        let action = makeAction(amount: amount, target: target)

        if action.type.isEnter, let state = try await allowance(action: action) {
            return state
        }

        return try await stages.resolveCommon(action: action, stepPlan: stepPlan)
    }

    private func allowance(action: StakingAction) async throws -> StakeFlowState? {
        guard let allowanceService, let spender = stages.stakingManager.allowanceAddress else {
            return nil
        }

        let allowanceState = try await allowanceService.allowanceState(
            amount: action.amount,
            spender: spender,
            approvePolicy: approvePolicy
        )

        switch allowanceState {
        case .enoughAllowance:
            return nil
        case .approveTransactionInProgress:
            return try await .prerequisite(.approve(.inProgress(stakingFee: stages.estimateFee(action: action))))
        case .revokeAndPermissionRequired:
            throw StakeModelError.revokeAndApproveNotSupported
        case .permissionRequired(let approveData):
            return try await permissionRequired(approveData: approveData, action: action)
        }
    }

    private func permissionRequired(approveData: ApproveTransactionData, action: StakingAction) async throws -> StakeFlowState {
        tokenFeeProvidersManager.update(
            input: .approve(txData: approveData.txData, toContractAddress: approveData.toContractAddress)
        )
        await tokenFeeProvidersManager.updateFees().value

        switch tokenFeeProvidersManager.selectedTokenFee.value {
        case .failure(let error):
            return .failure(.network(error))
        case .loading:
            break
        case .success(let approveFee):
            if let validationError = stages.validate(amount: .zero, fee: approveFee.amount.value) {
                return validationError
            }
        }

        return try await .prerequisite(.approve(.required(approveData, stakingFee: stages.estimateFee(action: action))))
    }
}
