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
    private let summaryStep: SendNewSummaryStep
    private let finishStep: SendNewFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let action: StakingSingleActionModel.Action

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        summaryStep: SendNewSummaryStep,
        finishStep: SendNewFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        action: UnstakingModel.Action
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
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
        case .newSummary:
            return .init(title: summaryTitleProvider.title, subtitle: summaryTitleProvider.subtitle, trailingViewType: .closeButton)
        case .newFinish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newSummary: .init(action: .action)
        case .newFinish: .init(action: .close)
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
