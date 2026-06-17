//
//  StakeStepsManager.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking
import TangemLocalization

/// The single V2 staking steps manager, replacing the four legacy per-flow managers. The step graph is
/// derived from the flow shape — which optional steps exist (`amountStep` iff the amount is editable,
/// `targetsStep` iff a validator is selectable) plus the action type. The approve/stake bottom-button
/// toggle is driven by the model's `flowActionTypePublisher`.
final class StakeStepsManager {
    private let amountStep: SendAmountStep?
    private let targetsStep: StakingTargetsStep?
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let actionType: StakingAction.ActionType

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []
    private weak var output: SendStepsManagerOutput?

    init(
        flowActionTypePublisher: AnyPublisher<SendFlowActionType, Never>,
        actionType: StakingAction.ActionType,
        amountStep: SendAmountStep?,
        targetsStep: StakingTargetsStep?,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider
    ) {
        self.actionType = actionType
        self.amountStep = amountStep
        self.targetsStep = targetsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider

        stack = [Self.makeInitialStep(actionType: actionType, amountStep: amountStep, targetsStep: targetsStep, summaryStep: summaryStep)]
        bind(flowActionTypePublisher: flowActionTypePublisher)
    }

    /// Editable amount → amount-first (stake, partial unstake); restake picks a validator first;
    /// everything else (fixed stake, full unstake, single action) opens on the summary.
    private static func makeInitialStep(
        actionType: StakingAction.ActionType,
        amountStep: SendAmountStep?,
        targetsStep: StakingTargetsStep?,
        summaryStep: SendSummaryStep
    ) -> SendStep {
        if let amountStep { return amountStep }
        if case .pending(.restake) = actionType, let targetsStep { return targetsStep }
        return summaryStep
    }

    private func bind(flowActionTypePublisher: AnyPublisher<SendFlowActionType, Never>) {
        flowActionTypePublisher
            .withWeakCaptureOf(self)
            .sink { manager, actionType in
                manager.output?.update(flowActionType: actionType)
            }
            .store(in: &bag)
    }

    private func currentStep() -> SendStep {
        stack.last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .amount, .targets:
            return summaryStep
        default:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        stack.append(step)
        output?.update(step: step)
    }

    private func back() {
        guard !stack.isEmpty else {
            // Ignore double click
            return
        }

        stack.removeLast()
        output?.update(step: currentStep())
    }
}

// MARK: - SendStepsManager

extension StakeStepsManager: SendStepsManager {
    /// Only the amount-first flows open the keyboard — which is exactly when an amount step exists.
    var initialKeyboardState: Bool { amountStep != nil }

    var initialFlowActionType: SendFlowActionType { actionType.sendFlowActionType }

    var initialStep: any SendStep {
        Self.makeInitialStep(actionType: actionType, amountStep: amountStep, targetsStep: targetsStep, summaryStep: summaryStep)
    }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .amount:
            return .init(title: Localization.commonAmount, trailingViewType: .closeButton)
        case .targets:
            return .init(title: Localization.stakingValidator, trailingViewType: .closeButton)
        case .summary:
            return .init(title: summaryTitleProvider.title, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        let isEditAction = stack.contains(where: { $0.type.isSummary })

        switch currentStep().type {
        case .amount where isEditAction: return .init(action: .continue)
        case .targets where isEditAction: return .init(action: .continue)
        case .amount: return .init(action: .next)
        case .targets: return .init(action: .next)
        case .summary: return .init(action: .action)
        case .finish: return .init(action: .close)
        default: return .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        back()
    }

    func performNext() {
        guard let step = getNextStep() else {
            return
        }

        func openNext() {
            next(step: step)
        }

        guard currentStep().canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension StakeStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        guard currentStep().type.isSummary, let targetsStep else {
            assertionFailure("This code should only be called from summary with a validator step")
            return
        }

        next(step: targetsStep)
    }

    func summaryStepRequestEditAmount() {
        guard currentStep().type.isSummary, let amountStep else {
            assertionFailure("This code should only be called from summary with an amount step")
            return
        }

        next(step: amountStep)
    }
}
