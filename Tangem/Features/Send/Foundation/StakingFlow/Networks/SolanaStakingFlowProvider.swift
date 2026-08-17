//
//  SolanaStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// Solana native multi-validator staking: editable stake amount, validator selection, partial unstake,
/// no approval or account-initialization prerequisite.
///
/// Its one specialness is the rent-exemption preflight: leaving a position must not drop the fee payer
/// below the rent-exempt minimum, which StakeKit rejects with a 400 rather than a usable error.
struct SolanaStakingFlowProvider: GenericStakingFlowProvider {
    let action: StakingAction
    let stages: StakeStagesResolver
    let preflightValidator: StakingPreflightValidator?

    var isStakeAmountEditable: Bool { true }
    var chainAllowsPartialUnstake: Bool { true }

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        let action = makeAction(amount: amount, target: target)

        if !action.type.isEnter, let failure = await preflightValidator?.validate() {
            try Task.checkCancellation()
            return .failure(.transaction(failure.validationError, fee: failure.estimatedFee, spendsAmount: false))
        }

        try Task.checkCancellation()

        return try await stages.resolveCommon(action: action, stepPlan: stepPlan, enterSpendsAmount: enterSpendsAmount)
    }
}
