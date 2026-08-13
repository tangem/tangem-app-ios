//
//  StakingFlowProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

/// A per-network staking flow entity. Each conformer knows its concrete network's specifics and
/// composes the shared `StakeStagesResolver`, running only the stages that network actually needs.
///
/// A provider is created per action (stake / unstake / claim …); the action it serves is fixed at init.
///
/// It is also the flow's only door to `StakingManager` — `StakeModel` never holds the manager itself.
protocol StakingFlowProvider {
    var actionType: StakingAction.ActionType { get }
    var stepPlan: StakeStepPlan { get }
    /// Whether the flow lets the user edit the amount.
    var isAmountEditable: Bool { get }
    /// The amount staked in the position this flow acts on (the action's baked amount).
    var stakedBalance: Decimal { get }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { get }
    func makeAction(amount: Decimal?, target: StakingTargetInfo?) -> StakingAction
    func buildTransaction(action: StakingAction) async throws -> StakingTransactionAction
    func transactionDidSent(action: StakingAction)
    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState
    /// Re-derive the ready state for an already-known fee, skipping fee estimation. Used when the
    /// dispatcher reports a changed fee mid-send (P2P `feeIncreased`) and the flow must re-state.
    func finalize(amount: Decimal, fee: Decimal, target: StakingTargetInfo?) -> StakeFlowState
}

/// The common pooled/validator staking flow, shared by every such network regardless of backend
/// (StakeKit or P2P — the backend lives in the manager, not here). Conformers declare their network's
/// traits; the default implementation derives the step plan, builds the action, and runs the common
/// `estimate → finalize` path. Networks with an enter-prerequisite (approval, min-amount) override
/// `updateState` to prepend it.
protocol GenericStakingFlowProvider: StakingFlowProvider {
    var action: StakingAction { get }
    var stages: StakeStagesResolver { get }
    var isStakeAmountEditable: Bool { get }
    var chainAllowsPartialUnstake: Bool { get }
    /// Whether entering a position moves the staked amount out of the wallet. False on chains that stake
    /// the balance in place (Cardano's delegation certificate), where only the fee and the chain's deposit
    /// are actually spent — there the amount must not be validated against the balance.
    var enterSpendsAmount: Bool { get }
}

extension GenericStakingFlowProvider {
    var enterSpendsAmount: Bool { true }

    var actionType: StakingAction.ActionType { action.displayType }
    var isAmountEditable: Bool { stepPlan.amount.isEditable }
    var stakedBalance: Decimal { action.amount }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { stages.statePublisher }

    func buildTransaction(action: StakingAction) async throws -> StakingTransactionAction {
        try await stages.buildTransaction(action: action)
    }

    func transactionDidSent(action: StakingAction) {
        stages.transactionDidSent(action: action)
    }

    var stepPlan: StakeStepPlan {
        GenericStakingProfile.stepPlan(
            for: action,
            isStakeAmountEditable: isStakeAmountEditable,
            isPartialUnstakeAllowed: isPartialUnstakeAllowed
        )
    }

    func makeAction(amount: Decimal?, target: StakingTargetInfo?) -> StakingAction {
        GenericStakingProfile.makeAction(stepPlan: stepPlan, action: action, amount: amount, target: target)
    }

    func updateState(amount: Decimal?, target: StakingTargetInfo?) async throws -> StakeFlowState {
        try await stages.resolveCommon(
            action: makeAction(amount: amount, target: target),
            stepPlan: stepPlan,
            enterSpendsAmount: enterSpendsAmount
        )
    }

    func finalize(amount: Decimal, fee: Decimal, target: StakingTargetInfo?) -> StakeFlowState {
        stages.finalize(
            amount: amount,
            fee: fee,
            target: target,
            isAmountEditable: stepPlan.amount.isEditable,
            includesStakesCount: stepPlan.includesStakesCount,
            isEnter: action.type.isEnter,
            enterSpendsAmount: enterSpendsAmount
        )
    }

    /// Partial unstake needs both the chain's permission and a preferred validator on the position.
    var isPartialUnstakeAllowed: Bool {
        guard chainAllowsPartialUnstake, let target = action.targetType.target else { return false }
        return target.preferred
    }
}

extension StakingFlowProvider {
    /// Re-derives the flow through `finalize` when the transaction's real fee exceeds a fee-included
    /// estimate (the amount must shrink again); nil when the estimate holds and it can dispatch as-is.
    func reconcileBuiltFee(
        enteredAmount: Decimal?,
        confirmed: StakeFlowState.Ready,
        builtTransaction: StakingTransactionAction,
        target: StakingTargetInfo?
    ) -> StakeFlowState? {
        let builtFee = builtTransaction.transactions.reduce(Decimal.zero) { $0 + $1.fee }
        guard confirmed.isFeeIncluded, builtFee > confirmed.fee else { return nil }
        return finalize(amount: enteredAmount ?? confirmed.amount, fee: builtFee, target: target)
    }
}

extension StakingAction.ActionType {
    /// Whether this action enters a staking position (and so may require approval / min-amount gating).
    var isEnter: Bool {
        switch self {
        case .stake, .pending(.stake): true
        default: false
        }
    }
}

/// The UI shape of a flow: how the amount and validator steps behave. Shared across networks because
/// the action-shapes (stake = editable + validators, unstake = amount only, claim = fixed) repeat.
struct StakeStepPlan {
    enum AmountMode: Equatable {
        case editable(preset: Decimal?)
        case fixed(Decimal)

        var isEditable: Bool {
            if case .editable = self { true } else { false }
        }

        func effectiveAmount(_ entered: Decimal?) -> Decimal {
            switch self {
            case .editable(let preset): entered ?? preset ?? .zero
            case .fixed(let value): value
            }
        }
    }

    let amount: AmountMode
    let hasValidatorSelection: Bool
    let includesStakesCount: Bool
    let summarySettings: SendSummaryViewModel.Settings
}

/// Shared action-shape derivation for the common staking flow. Networks pass their own knobs
/// (`isStakeAmountEditable`, `isPartialUnstakeAllowed`); everything else is common.
enum GenericStakingProfile {
    static func stepPlan(
        for action: StakingAction,
        isStakeAmountEditable: Bool,
        isPartialUnstakeAllowed: Bool
    ) -> StakeStepPlan {
        switch action.displayType {
        case .stake, .pending(.stake):
            isStakeAmountEditable
                ? StakeStepPlan(
                    amount: .editable(preset: nil),
                    hasValidatorSelection: true,
                    includesStakesCount: false,
                    summarySettings: .init(destinationEditableType: .editable, amountEditableType: .editable)
                )
                : StakeStepPlan(
                    amount: .fixed(action.amount),
                    hasValidatorSelection: true,
                    includesStakesCount: false,
                    summarySettings: .init(destinationEditableType: .editable, amountEditableType: .noEditable)
                )
        case .pending(.restake), .pending(.voteLocked):
            StakeStepPlan(
                amount: .fixed(action.amount),
                hasValidatorSelection: true,
                includesStakesCount: false,
                summarySettings: .init(destinationEditableType: .editable, amountEditableType: .noEditable)
            )
        case .unstake:
            StakeStepPlan(
                amount: isPartialUnstakeAllowed ? .editable(preset: action.amount) : .fixed(action.amount),
                hasValidatorSelection: false,
                includesStakesCount: true,
                summarySettings: .init(
                    destinationEditableType: isPartialUnstakeAllowed ? .editable : .noEditable,
                    amountEditableType: isPartialUnstakeAllowed ? .editable : .noEditable
                )
            )
        case .pending:
            StakeStepPlan(
                amount: .fixed(action.amount),
                hasValidatorSelection: false,
                includesStakesCount: true,
                summarySettings: .init(destinationEditableType: .noEditable, amountEditableType: .noEditable)
            )
        }
    }

    static func makeAction(
        stepPlan: StakeStepPlan,
        action: StakingAction,
        amount: Decimal?,
        target: StakingTargetInfo?
    ) -> StakingAction {
        let resolvedTarget: StakingTargetType = stepPlan.hasValidatorSelection
            ? target.map { .target($0) } ?? .empty
            : action.targetType

        return StakingAction(
            amount: stepPlan.amount.effectiveAmount(amount),
            targetType: resolvedTarget,
            type: action.type,
            displayType: action.displayType
        )
    }
}
