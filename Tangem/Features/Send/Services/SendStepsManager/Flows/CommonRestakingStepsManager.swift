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
    private let validatorsStep: StakingValidatorsStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let actionType: SendFlowActionType

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        validatorsStep: StakingValidatorsStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        actionType: SendFlowActionType
    ) {
        self.validatorsStep = validatorsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.actionType = actionType

        stack = [actionType == .restake ? validatorsStep : summaryStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .validators:
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
        actionType == .restake ? validatorsStep : summaryStep
    }

    var shouldShowDismissAlert: Bool {
        return false
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .validators:
            return .init(title: Localization.stakingValidator, trailingViewType: .closeButton)
        case .summary:
            return .init(title: summaryTitleProvider.title, subtitle: summaryTitleProvider.subtitle, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        let isEditAction = stack.contains(where: { $0.type.isSummary })

        switch currentStep().type {
        case .validators where isEditAction: return .init(action: .continue)
        case .validators: return .init(action: .next)
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
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: validatorsStep)
    }
}
