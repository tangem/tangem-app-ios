//
//  CommonRestakingStepsManager 2.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//
import Combine
import TangemStaking
import TangemLocalization

class CommonRestakingStepsManager {
    private let targetsStep: StakingTargetsStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let confirmTransactionPolicy: ConfirmTransactionPolicy
    private let actionType: SendFlowActionType

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        targetsStep: StakingTargetsStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy,
        actionType: SendFlowActionType
    ) {
        self.targetsStep = targetsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy
        self.actionType = actionType

        stack = [actionType == .restake ? targetsStep : summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .targets:
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

extension CommonRestakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType {
        actionType
    }

    var initialStep: any SendStep {
        actionType == .restake ? targetsStep : summaryStep
    }

    var shouldShowDismissAlert: Bool {
        return false
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
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
        case .targets where isEditAction: return .init(action: .continue)
        case .targets: return .init(action: .next)
        case .summary: return .init(action: confirmTransactionPolicy.needsHoldToConfirm ? .holdAction : .action)
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
        next(step: summaryStep)
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

extension CommonRestakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: targetsStep)
    }
}
