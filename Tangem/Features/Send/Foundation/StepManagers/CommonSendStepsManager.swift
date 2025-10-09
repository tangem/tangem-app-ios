//
//  CommonSendStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class CommonSendStepsManager {
    private let amountStep: SendNewAmountStep
    private let destinationStep: SendDestinationStep
    private let summaryStep: SendNewSummaryStep
    private let finishStep: SendNewFinishStep
    private let feeSelector: FeeSelectorContentViewModel
    private let providersSelector: SendSwapProvidersSelectorViewModel
    private let summaryTitleProvider: SendSummaryTitleProvider

    private var stack: [SendStep]
    private weak var router: SendRoutable?
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        amountStep: SendNewAmountStep,
        destinationStep: SendDestinationStep,
        summaryStep: SendNewSummaryStep,
        finishStep: SendNewFinishStep,
        feeSelector: FeeSelectorContentViewModel,
        providersSelector: SendSwapProvidersSelectorViewModel,
        summaryTitleProvider: SendSummaryTitleProvider,
        router: SendRoutable
    ) {
        self.amountStep = amountStep
        self.destinationStep = destinationStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.feeSelector = feeSelector
        self.providersSelector = providersSelector
        self.summaryTitleProvider = summaryTitleProvider
        self.router = router

        stack = [amountStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> (SendStep)? {
        switch currentStep().type {
        case .destination:
            return summaryStep
        case .newAmount:
            return destinationStep
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

extension CommonSendStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }
    var initialFlowActionType: SendFlowActionType { .send }
    var initialStep: any SendStep { amountStep }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .newAmount:
            return .init(title: Localization.commonAmount, trailingViewType: .closeButton)
        case .destination where isEditAction:
            return .init(title: Localization.commonAddress, trailingViewType: .closeButton)
        case .destination:
            return .init(title: Localization.commonAddress, leadingViewType: .backButton, trailingViewType: .closeButton)
        case .newSummary:
            return .init(title: summaryTitleProvider.title, leadingViewType: .backButton, trailingViewType: .closeButton)
        case .newFinish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newAmount where isEditAction: .init(action: .continue)
        case .destination where isEditAction: .init(action: .continue)
        case .newAmount: .init(action: .next)
        case .destination: .init(action: .next)
        case .newSummary: .init(action: .action)
        case .newFinish: .init(action: .close)
        default: .empty
        }
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

    func resetFlow() {
        stack = [amountStep]
        output?.update(step: amountStep)
    }

    func performBack() {
        switch currentStep().type {
        case .newAmount where isEditAction:
            amountStep.cancelChanges()
        case .destination where isEditAction:
            destinationStep.cancelChanges()
        default:
            break
        }

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

extension CommonSendStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: destinationStep)
    }

    func summaryStepRequestEditAmount() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditFee() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        router?.openFeeSelector(viewModel: feeSelector)
    }

    func summaryStepRequestEditProviders() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        router?.openSwapProvidersSelector(viewModel: providersSelector)
    }
}

// MARK: - SendDestinationStepRoutable

extension CommonSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}
