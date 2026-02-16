//
//  CommonSwapStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class CommonSwapStepsManager {
    private let summaryStep: SwapSummaryStep
    private let finishStep: SendFinishStep
    private let feeSelectorBuilder: SendFeeSelectorBuilder
    private let providersSelector: SendSwapProvidersSelectorViewModel

    private var stack: [SendStep]
    private weak var router: SendRoutable?
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        summaryStep: SwapSummaryStep,
        finishStep: SendFinishStep,
        feeSelectorBuilder: SendFeeSelectorBuilder,
        providersSelector: SendSwapProvidersSelectorViewModel,
        router: SendRoutable
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.feeSelectorBuilder = feeSelectorBuilder
        self.providersSelector = providersSelector
        self.router = router

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

// MARK: - SwapStepsManager

extension CommonSwapStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }
    var initialFlowActionType: SendFlowActionType { .swap }
    var initialStep: any SendStep { summaryStep }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .swap:
            return .init(title: Localization.commonSwap, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .swap: .init(action: .none)
        case .finish: .init(action: .close)
        default: .empty
        }
    }

    var shouldShowDismissAlert: Bool {
        return false
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performFinish() {
        next(step: finishStep)
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonSwapStepsManager: SwapSummaryStepRoutable {
    func summaryStepRequestEditSourceToken() {
        // [REDACTED_TODO_COMMENT]
    }

    func summaryStepRequestEditReceiveToken() {
        // [REDACTED_TODO_COMMENT]
    }

    func summaryStepRequestEditFee() {
        router?.openFeeSelector(feeSelectorBuilder: feeSelectorBuilder)
    }

    func summaryStepRequestEditProviders() {
        router?.openSwapProvidersSelector(viewModel: providersSelector)
    }
}
