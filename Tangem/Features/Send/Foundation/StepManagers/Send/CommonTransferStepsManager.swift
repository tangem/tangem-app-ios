//
//  CommonTransferStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class CommonTransferStepsManager {
    private let amountStep: SendAmountStep
    private let destinationStep: SendDestinationStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let feeSelectorBuilder: SendFeeSelectorBuilder
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let flowActionType: SendFlowActionType
    private let selectedInitialStep: InitialStep

    private var stack: [SendStep]
    private weak var router: SendRoutable?
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        amountStep: SendAmountStep,
        destinationStep: SendDestinationStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        feeSelectorBuilder: SendFeeSelectorBuilder,
        summaryTitleProvider: SendSummaryTitleProvider,
        flowActionType: SendFlowActionType = .send,
        initialStep: InitialStep = .amount,
        router: SendRoutable
    ) {
        self.amountStep = amountStep
        self.destinationStep = destinationStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.feeSelectorBuilder = feeSelectorBuilder
        self.summaryTitleProvider = summaryTitleProvider
        self.flowActionType = flowActionType
        selectedInitialStep = initialStep
        self.router = router

        switch initialStep {
        case .amount, .amountThenSummary:
            stack = [amountStep]
        case .summary:
            stack = [amountStep, destinationStep, summaryStep]
        }
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func step(for type: InitialStep) -> SendStep {
        switch type {
        case .amount, .amountThenSummary:
            return amountStep
        case .summary:
            return summaryStep
        }
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .destination:
            return summaryStep
        case .amount where selectedInitialStep == .amountThenSummary:
            return summaryStep
        case .amount:
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

extension CommonTransferStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }
    var initialFlowActionType: SendFlowActionType { flowActionType }
    var initialStep: any SendStep { step(for: selectedInitialStep) }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .amount:
            return .init(title: Localization.commonAmount, trailingViewType: .closeButton)
        case .destination where isEditAction:
            return .init(title: Localization.commonAddress, trailingViewType: .closeButton)
        case .destination:
            return .init(title: Localization.commonAddress, leadingViewType: .backButton, trailingViewType: .closeButton)
        case .summary:
            return .init(title: summaryTitleProvider.title, leadingViewType: .backButton, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .amount where isEditAction: .init(action: .continue)
        case .destination where isEditAction: .init(action: .continue)
        case .amount: .init(action: .next)
        case .destination: .init(action: .next)
        case .summary: .init(action: .action)
        case .finish: .init(action: .close)
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

    func performBack() {
        switch currentStep().type {
        case .amount where isEditAction:
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

// MARK: - SendAmountStepRoutable

extension CommonTransferStepsManager: SendAmountStepRoutable {
    func openReceiveTokensList(onDismiss: (() -> Void)?) {
        assertionFailure("This action is not implemented")
    }

    func openRateInfoSheet(rateType: RateInfoSheetViewModel.RateType, onDismiss: @escaping () -> Void) {
        router?.openRateInfoSheet(rateType: rateType, onDismiss: onDismiss)
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonTransferStepsManager: SendSummaryStepsRoutable {
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

        router?.openFeeSelector(feeSelectorBuilder: feeSelectorBuilder)
    }
}

// MARK: - SendDestinationStepRoutable

extension CommonTransferStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        guard currentStep().type.isDestination else {
            return
        }

        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}

// MARK: - Auxiliary types

extension CommonTransferStepsManager {
    enum InitialStep {
        case amount
        case amountThenSummary
        case summary

        init(parameters: PredefinedSendParameters?) {
            switch parameters?.initialStep {
            case .none, .amount: self = .amount
            case .amountThenSummary: self = .amountThenSummary
            case .summary: self = .summary
            }
        }
    }
}
