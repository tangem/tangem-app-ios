//
//  CommonUnstakingStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonUnstakingStepsManager {
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [summaryStep]
    }

    private func next(step: SendStep) {
        stack.append(step)

        switch step.type {
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .amount, .destination, .fee, .summary, .validators:
            assertionFailure("There is no next step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonUnstakingStepsManager: SendStepsManager {
    var initialState: SendStepsManagerViewState {
        .init(step: summaryStep, action: .send, backButtonVisible: false)
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        assertionFailure("There's not back action in this flow")
    }

    func performNext() {
        assertionFailure("There's not next action in this flow")
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assertionFailure("There's not continue action in this flow")
    }
}
