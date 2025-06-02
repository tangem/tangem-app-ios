//
//  CommonNewSendStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class CommonNewSendStepsManager {
    private let amountStep: SendNewAmountStep
    private let destinationStep: SendNewDestinationStep
    private let summaryStep: SendNewSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        amountStep: SendNewAmountStep,
        destinationStep: SendNewDestinationStep,
        summaryStep: SendNewSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.amountStep = amountStep
        self.destinationStep = destinationStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [amountStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialState.step
    }

    private func getNextStep() -> (SendStep)? {
        switch currentStep().type {
        case .newDestination:
            return summaryStep
        case .newAmount:
            return destinationStep
        case .fee, .validators, .summary, .newSummary, .finish, .onramp, .amount, .destination:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .summary, .newSummary:
            output?.update(state: .init(step: step, action: .action))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .newAmount where isEditAction,
             .newDestination where isEditAction,
             .fee where isEditAction:
            output?.update(state: .init(step: step, action: .continue))
        case .newAmount, .newDestination:
            output?.update(state: .init(step: step, action: .next, backButtonVisible: true))
        case .amount, .fee, .validators, .onramp, .destination:
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
        case .summary, .newSummary:
            output?.update(state: .init(step: step, action: .action))
        default:
            output?.update(state: .init(step: step, action: .next))
        }
    }
}

// MARK: - SendStepsManager

extension CommonNewSendStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }

    var initialFlowActionType: SendFlowActionType { .send }

    var initialState: SendStepsManagerViewState {
        .init(step: amountStep, action: .next, backButtonVisible: false)
    }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
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

        guard currentStep().canBeClosed(continueAction: back) else {
            return
        }

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonNewSendStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditDestination() {
        guard case .newSummary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: destinationStep)
    }

    func summaryStepRequestEditAmount() {
        guard case .newSummary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditFee() {
        guard case .newSummary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - SendDestinationStepRoutable

extension CommonNewSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}
