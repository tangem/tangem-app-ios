//
//  CommonSendStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

class CommonSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let amountStep: SendAmountStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    private var isEditAction: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    init(
        destinationStep: SendDestinationStep,
        amountStep: SendAmountStep,
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider
    ) {
        self.destinationStep = destinationStep
        self.amountStep = amountStep
        self.feeStep = feeStep
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
        case .destination:
            return amountStep
        case .amount:
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

extension CommonSendStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { false }
    var initialFlowActionType: SendFlowActionType { .send }
    var initialStep: any SendStep { destinationStep }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .destination:
            return .init(
                title: Localization.sendRecipientLabel,
                leadingViewType: .closeButton,
                trailingViewType: .qrCodeButton { [weak self] in
                    self?.destinationStep.userDidRequestScanQRCode()
                }
            )
        case .amount:
            return .init(title: Localization.commonAmount, leadingViewType: .closeButton)
        case .fee:
            return .init(title: Localization.commonFeeSelectorTitle, leadingViewType: .closeButton)
        case .summary:
            return .init(title: summaryTitleProvider.title, subtitle: summaryTitleProvider.subtitle, leadingViewType: .closeButton)
        case .finish:
            return .init(leadingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .destination where isEditAction: .init(action: .continue)
        case .amount where isEditAction: .init(action: .continue)
        case .fee where isEditAction: .init(action: .continue)
        case .destination: .init(action: .next)
        case .amount: .init(action: .next, backButtonVisible: true)
        case .summary: .init(action: .action)
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

        next(step: feeStep)
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
