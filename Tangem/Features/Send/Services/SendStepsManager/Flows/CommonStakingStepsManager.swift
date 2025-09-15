//
//  CommonStakingStepsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

class CommonStakingStepsManager {
    private let provider: StakingModelStateProvider
    private let amountStep: SendAmountStep
    private let validatorsStep: StakingValidatorsStep?
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider

    private var stack: [SendStep]
    private var bag: Set<AnyCancellable> = []

    private weak var output: SendStepsManagerOutput?

    init(
        provider: StakingModelStateProvider,
        amountStep: SendAmountStep,
        validatorsStep: StakingValidatorsStep?,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider
    ) {
        self.provider = provider
        self.amountStep = amountStep
        self.validatorsStep = validatorsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider

        stack = [amountStep]
        bind()
    }

    private func bind() {
        provider.state
            .withWeakCaptureOf(self)
            .sink { stepsManager, state in
                switch state {
                case .loading, .networkError, .validationError:
                    break

                case .readyToApprove:
                    stepsManager.output?.update(flowActionType: .approve)

                case .approveTransactionInProgress, .readyToStake:
                    stepsManager.output?.update(flowActionType: .stake)
                }
            }
            .store(in: &bag)
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func getNextStep() -> SendStep? {
        switch currentStep().type {
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

extension CommonStakingStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { true }
    var initialFlowActionType: SendFlowActionType { .stake }
    var initialStep: any SendStep { amountStep }

    var shouldShowDismissAlert: Bool {
        stack.contains(where: { $0.type.isSummary })
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .amount:
            return .init(title: Localization.commonAmount, trailingViewType: .closeButton)
        case .validators:
            return .init(title: Localization.stakingValidator, trailingViewType: .closeButton)
        case .summary:
            return .init(title: summaryTitleProvider.title, subtitle: summaryTitleProvider.subtitle, trailingViewType: .closeButton)
        case .finish:
            return .init(trailingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        let isEditAction = stack.contains(where: { $0.type.isSummary })

        switch currentStep().type {
        case .amount where isEditAction: return .init(action: .continue)
        case .validators where isEditAction: return .init(action: .continue)
        case .amount: return .init(action: .next)
        case .summary: return .init(action: .action)
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

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonStakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        guard let validatorsStep else {
            return
        }

        next(step: validatorsStep)
    }

    func summaryStepRequestEditAmount() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        assertionFailure("This steps is not tappable in this flow")
    }
}
