//
//  CommonNFTSendStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class CommonNFTSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let feeSelectorBuilder: SendFeeSelectorBuilder
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let confirmTransactionPolicy: ConfirmTransactionPolicy
    private weak var router: SendRoutable?

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        destinationStep: SendDestinationStep,
        feeSelectorBuilder: SendFeeSelectorBuilder,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        confirmTransactionPolicy: ConfirmTransactionPolicy,
        router: SendRoutable
    ) {
        self.destinationStep = destinationStep
        self.feeSelectorBuilder = feeSelectorBuilder
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.confirmTransactionPolicy = confirmTransactionPolicy
        self.router = router

        stack = [destinationStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .destination:
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

extension CommonNFTSendStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }
    var initialFlowActionType: SendFlowActionType { .send }
    var initialStep: any SendStep { destinationStep }

    var shouldShowDismissAlert: Bool {
        if currentStep().type.isFinish {
            return false
        }

        return stack.contains(where: { $0.type.isSummary })
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .destination:
            return .init(title: Localization.wcCommonAddress, trailingViewType: .closeButton)
        case .summary:
            return .init(
                title: summaryTitleProvider.title,
                leadingViewType: .backButton,
                trailingViewType: .closeButton
            )
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .destination where isEditAction: .init(action: .continue)
        case .destination: .init(action: .next)
        case .summary: .init(action: confirmTransactionPolicy.needsHoldToConfirm ? .holdAction : .action)
        case .finish: .init(action: .close)
        default: .empty
        }
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

extension CommonNFTSendStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        guard currentStep().type.isSummary else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: destinationStep)
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

extension CommonNFTSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}
