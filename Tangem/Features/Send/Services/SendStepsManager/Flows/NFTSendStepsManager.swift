//
//  NFTSendStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class NFTSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        destinationStep: SendDestinationStep,
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.destinationStep = destinationStep
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [destinationStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialState.step
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .destination:
            return summaryStep
        case .amount,
             .newAmount,
             .newDestination:
            assertionFailure("Invalid step for this flow: '\(currentStep().type)'")
            return summaryStep
        case .fee,
             .validators,
             .summary,
             .newSummary,
             .finish,
             .onramp,
             .newFinish:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .destination where isEditAction,
             .fee where isEditAction:
            output?.update(state: .init(step: step, action: .continue))
        case .destination:
            output?.update(state: .init(step: step, action: .next, backButtonVisible: true))
        case .amount,
             .newAmount,
             .newDestination,
             .newSummary,
             .newFinish:
            assertionFailure("Invalid step for this flow: '\(step.type)'")
        case .fee,
             .validators,
             .onramp:
            assertionFailure("There is no next step")
        }
    }

    private func back() {
        guard !stack.isEmpty else {
            // Ignore double click
            return
        }

        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        default:
            output?.update(state: .init(step: step, action: .next))
        }
    }
}

// MARK: - SendStepsManager

extension NFTSendStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }

    var initialFlowActionType: SendFlowActionType { .send }

    var initialState: SendStepsManagerViewState {
        .init(step: destinationStep, action: .next, backButtonVisible: false)
    }

    var shouldShowDismissAlert: Bool {
        if currentStep().type.isFinish {
            return false
        }

        return stack.contains(where: { $0.type.isSummary })
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        assertionFailure("There's no back action in this flow")
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

        guard currentStep().canBeClosed(continueAction: back) else {
            return
        }

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension NFTSendStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditDestination() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: destinationStep)
    }

    func summaryStepRequestEditAmount() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: feeStep)
    }
}

// MARK: - SendDestinationStepRoutable

extension NFTSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}
