//
//  UnsupportedStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStaking

/// A provider for networks that reach the factory but are not offered for staking. It builds no usable
/// flow and deterministically resolves to a failure, so a release build surfaces an error instead of
/// trapping or silently running another network's flow.
struct UnsupportedStakingFlowProvider: StakingFlowProvider {
    let action: StakingAction

    var actionType: StakingAction.ActionType { action.displayType }

    var stepPlan: StakeStepPlan {
        StakeStepPlan(
            amount: .fixed(action.amount),
            hasValidatorSelection: false,
            includesStakesCount: false,
            summarySettings: .init(destinationEditableType: .noEditable, amountEditableType: .noEditable)
        )
    }

    func makeAction(amount: Decimal?, target: StakingTargetInfo?) -> StakingAction {
        action
    }

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        .failure(.network(StakeModelError.networkNotSupported))
    }

    func finalize(amount: Decimal, fee: Decimal, target: StakingTargetInfo?) -> StakeFlowState {
        .failure(.network(StakeModelError.networkNotSupported))
    }
}
