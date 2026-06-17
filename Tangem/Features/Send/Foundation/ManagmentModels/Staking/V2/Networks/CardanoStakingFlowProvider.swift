//
//  CardanoStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

/// Cardano native staking. The stake amount is not editable (the full available balance is staked),
/// partial unstake is unsupported, and a stake is gated by the yield's minimum-amount rule.
struct CardanoStakingFlowProvider: CommonStakingFlow {
    let action: StakingAction
    let stages: StakingFlowStages
    let minAmountValidator: SendAmountValidator

    var isStakeAmountEditable: Bool { false }
    var chainAllowsPartialUnstake: Bool { false }

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        let action = makeAction(amount: amount, target: target)

        if action.type.isEnter, let state = minAmount(amount: action.amount) {
            return state
        }

        return try await stages.resolveCommon(action: action, stepPlan: stepPlan)
    }

    /// Cardano stakes the full available balance, gated by the yield's minimum. Mirrors the legacy
    /// restaking flow: only a `StakingValidationError` surfaces here, anything else falls through.
    private func minAmount(amount: Decimal) -> StakeFlowState? {
        do {
            try minAmountValidator.validate(amount: amount)
            return nil
        } catch let error as StakingValidationError {
            return .failure(.staking(error))
        } catch {
            return nil
        }
    }
}
