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
    private let tokenSelectorBuilder: SwapTokenSelectorViewModelBuilder
    private var stack: [SendStep]
    private weak var router: SendRoutable?
    private weak var output: SendStepsManagerOutput?

    init(
        summaryStep: SwapSummaryStep,
        finishStep: SendFinishStep,
        feeSelectorBuilder: SendFeeSelectorBuilder,
        providersSelector: SendSwapProvidersSelectorViewModel,
        tokenSelectorBuilder: SwapTokenSelectorViewModelBuilder,
        router: SendRoutable
    ) {
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.feeSelectorBuilder = feeSelectorBuilder
        self.providersSelector = providersSelector
        self.tokenSelectorBuilder = tokenSelectorBuilder
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
    func summaryStepRequestEditSourceToken(tokenItem: TokenItem) {
        router?.openSwapTokenSelector(
            swapTokenSelectorViewModelBuilder: tokenSelectorBuilder,
            direction: .toDestination(tokenItem)
        )
    }

    func summaryStepRequestEditReceiveToken(tokenItem: TokenItem) {
        router?.openSwapTokenSelector(
            swapTokenSelectorViewModelBuilder: tokenSelectorBuilder,
            direction: .fromSource(tokenItem)
        )
    }

    func summaryStepRequestEditFee() {
        router?.openFeeSelector(feeSelectorBuilder: feeSelectorBuilder)
    }

    func summaryStepRequestEditProviders() {
        router?.openSwapProvidersSelector(viewModel: providersSelector)
    }
}
