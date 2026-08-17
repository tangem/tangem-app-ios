//
//  UnsupportedStakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemStaking

/// A provider for networks that reach the factory but are not offered for staking. It builds no usable
/// flow and deterministically resolves to a failure, so a release build surfaces an error instead of
/// trapping or silently running another network's flow.
struct UnsupportedStakingFlowProvider: StakingFlowProvider {
    let action: StakingAction

    var actionType: StakingAction.ActionType { action.displayType }
    var isAmountEditable: Bool { false }
    var stakedBalance: Decimal { action.amount }

    /// `.notEnabled` rather than `.loading`, so the flow doesn't sit spinning instead of showing the failure.
    var statePublisher: AnyPublisher<StakingManagerState, Never> { .just(output: .notEnabled) }

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

    func buildTransaction(action: StakingAction) async throws -> StakingTransactionAction {
        throw StakeModelError.networkNotSupported
    }

    func transactionDidSent(action: StakingAction) {}

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        .failure(.network(StakeModelError.networkNotSupported))
    }

    func finalize(amount: Decimal, fee: Decimal, target: StakingTargetInfo?) -> StakeFlowState {
        .failure(.network(StakeModelError.networkNotSupported))
    }
}
