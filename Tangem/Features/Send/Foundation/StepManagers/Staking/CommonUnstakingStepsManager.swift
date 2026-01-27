//
//  CommonUnstakingStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization

class CommonUnstakingStepsManager {
    private let amountStep: SendAmountStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let action: UnstakingModel.Action
    private let isPartialUnstakeAllowed: Bool

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        amountStep: SendAmountStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        action: UnstakingModel.Action,
        isPartialUnstakeAllowed: Bool
    ) {
        self.amountStep = amountStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.action = action
        self.isPartialUnstakeAllowed = isPartialUnstakeAllowed

        stack = [isPartialUnstakeAllowed ? amountStep : summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .amount:
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

extension CommonUnstakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { isPartialUnstakeAllowed }

    var initialFlowActionType: SendFlowActionType {
        switch action.type {
        case .unstake:
            return .unstake
        case .pending(.withdraw):
            return .withdraw
        case .pending(.claimRewards):
            return .claimRewards
        case .pending(.restakeRewards):
            return .restakeRewards
        case .pending(.voteLocked), .pending(.restake):
            return .stake
        case .pending(.unlockLocked):
            return .unlockLocked
        case .pending(.claimUnstaked):
            return .claimUnstaked
        case .stake, .pending(.stake):
            assertionFailure("Doesn't support in UnstakingFlow")
            return .unstake
        }
    }

    var initialStep: any SendStep {
        isPartialUnstakeAllowed ? amountStep : summaryStep
    }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .amount:
            return .init(title: Localization.commonAmount, trailingViewType: .closeButton)
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
        case .amount: return .init(action: .next)
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

extension CommonUnstakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditAmount() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }
}
