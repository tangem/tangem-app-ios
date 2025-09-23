//
//  CommonSellStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class CommonSellStepsManager {
    private let feeSelector: FeeSelectorContentViewModel
    private let summaryStep: SendNewSummaryStep
    private let finishStep: SendNewFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?
    weak var router: SendRoutable?

    init(
        feeSelector: FeeSelectorContentViewModel,
        summaryStep: SendNewSummaryStep,
        finishStep: SendNewFinishStep
    ) {
        self.feeSelector = feeSelector
        self.summaryStep = summaryStep
        self.finishStep = finishStep

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

extension CommonSellStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }
    var initialFlowActionType: SendFlowActionType { .send }
    var initialStep: SendStep { summaryStep }

    var shouldShowDismissAlert: Bool {
        return true
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .newSummary:
            return .init(title: Localization.commonSell, trailingViewType: .closeButton)
        case .newFinish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newSummary: return .init(action: .action)
        case .newFinish: return .init(action: .close)
        default: return .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        back()
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

extension CommonSellStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditFee() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        router?.openFeeSelector(viewModel: feeSelector)
    }
}
