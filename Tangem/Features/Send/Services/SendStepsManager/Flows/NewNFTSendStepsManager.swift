//
//  NewNFTSendStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class NewNFTSendStepsManager {
    private let destinationStep: SendNewDestinationStep
    private let feeSelector: FeeSelectorContentViewModel
    private let summaryStep: SendNewSummaryStep
    private let finishStep: SendNewFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider

    private var stack: [SendStep]
    weak var router: SendRoutable?
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        destinationStep: SendNewDestinationStep,
        feeSelector: FeeSelectorContentViewModel,
        summaryStep: SendNewSummaryStep,
        finishStep: SendNewFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider
    ) {
        self.destinationStep = destinationStep
        self.feeSelector = feeSelector
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider

        stack = [destinationStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
        case .newDestination:
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

extension NewNFTSendStepsManager: SendStepsManager {
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
        case .newDestination:
            return .init(title: Localization.wcCommonAddress, trailingViewType: .closeButton)
        case .newSummary:
            return .init(
                title: summaryTitleProvider.title,
                leadingViewType: .backButton,
                trailingViewType: .closeButton
            )
        case .newFinish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newDestination where isEditAction: .init(action: .continue)
        case .newDestination: .init(action: .next)
        case .newSummary: .init(action: .action)
        case .newFinish: .init(action: .close)
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

extension NewNFTSendStepsManager: SendSummaryStepsRoutable {
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

        router?.openFeeSelector(viewModel: feeSelector)
    }
}

// MARK: - SendDestinationStepRoutable

extension NewNFTSendStepsManager: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        if isEditAction {
            performContinue()
        } else {
            performNext()
        }
    }
}
