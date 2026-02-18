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
    private let feeSelectorBuilder: SendFeeSelectorBuilder
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let confirmTransactionPolicy: ConfirmTransactionPolicy

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?
    weak var router: SendRoutable?

    init(
        feeSelectorBuilder: SendFeeSelectorBuilder,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        confirmTransactionPolicy: ConfirmTransactionPolicy,
    ) {
        self.feeSelectorBuilder = feeSelectorBuilder
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.confirmTransactionPolicy = confirmTransactionPolicy

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
        case .summary:
            return .init(title: Localization.commonSell, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
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

        router?.openFeeSelector(feeSelectorBuilder: feeSelectorBuilder)
    }
}
