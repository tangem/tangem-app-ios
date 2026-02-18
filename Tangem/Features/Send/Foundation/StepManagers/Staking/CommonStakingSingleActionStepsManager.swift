//
//  CommonStakingSingleActionStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import TangemLocalization

class CommonStakingSingleActionStepsManager {
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let confirmTransactionPolicy: ConfirmTransactionPolicy
    private let action: StakingSingleActionModel.Action

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy,
        action: UnstakingModel.Action
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy
        self.action = action

        stack = [summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func next(step: SendStep) {
        stack.append(step)
        output?.update(step: step)
    }
}

// MARK: - SendStepsManager

extension CommonStakingSingleActionStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

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
        case .pending(.voteLocked):
            return .stake
        case .pending(.unlockLocked):
            return .unlockLocked
        case .pending(.restake):
            return .restake
        case .pending(.claimUnstaked):
            return .claimUnstaked
        case .stake, .pending(.stake):
            assertionFailure("Doesn't support in StakingSingleAction flow")
            return .unstake
        }
    }

    var initialStep: any SendStep { summaryStep }

    var shouldShowDismissAlert: Bool { false }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .summary:
            return .init(title: summaryTitleProvider.title, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .summary: .init(action: confirmTransactionPolicy.needsHoldToConfirm ? .holdAction : .action)
        case .finish: .init(action: .close)
        default: .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performFinish() {
        next(step: finishStep)
    }
}
