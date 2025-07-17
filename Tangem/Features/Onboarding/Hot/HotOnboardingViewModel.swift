//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

final class HotOnboardingViewModel: ObservableObject {
    @Published var leadingItem: HotOnboardingFlowNavigation.ActionItem?

    var currentStep: HotOnboardingFlowStep? {
        flowSteps[currentStepIndex]
    }

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let skipTitle = Localization.commonSkip

    @Published private var currentStepIndex: Int = 0

    private var flowBuilder: HotOnboardingFlowBuilder?
    private var flowSteps: [HotOnboardingFlowStep] = []

    private weak var coordinator: HotOnboardingRoutable?

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.coordinator = coordinator
        flowSteps = makeFlowSteps(flow: input.flow)
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func onDismissalAttempt() {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Helpers

private extension HotOnboardingViewModel {
    func makeFlowSteps(flow: HotOnboardingFlow) -> [HotOnboardingFlowStep] {
        switch flow {
        case .walletCreate:
            let flowBuilder = HotOnboardingWalletCreateFlowBuilder(coordinator: self)
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .walletImport:
            let flowBuilder = HotOnboardingWalletImportFlowBuilder(coordinator: self, navigationDelegate: self)
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .walletActivate(let userWalletModel):
            let flowBuilder = HotOnboardingWalletActivateFlowBuilder(
                userWalletModel: userWalletModel,
                coordinator: self,
                navigationDelegate: self
            )
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .accessCodeCreate(let userWalletModel):
            let flowBuilder = HotOnboardingAccessCodeCreateFlowBuilder(
                userWalletModel: userWalletModel,
                coordinator: self,
                navigationDelegate: self
            )
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .accessCodeChange(let userWalletModel, let needAccessCodeValidation):
            let flowBuilder = HotOnboardingAccessCodeChangeFlowBuilder(
                userWalletModel: userWalletModel,
                needAccessCodeValidation: needAccessCodeValidation,
                coordinator: self,
                navigationDelegate: self
            )
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .seedPhraseBackup(let userWalletModel):
            let flowBuilder = HotOnboardingSeedPhraseBackupFlowBuilder(userWalletModel: userWalletModel, coordinator: self)
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        case .seedPhraseReveal(let userWalletModel, let needAccessCodeValidation):
            let flowBuilder = HotOnboardingSeedPhraseRevealFlowBuilder(
                userWalletModel: userWalletModel,
                needAccessCodeValidation: needAccessCodeValidation,
                coordinator: self
            )
            self.flowBuilder = flowBuilder
            return flowBuilder.buildSteps()
        }
    }
}

// MARK: - Steps navigation

private extension HotOnboardingViewModel {
//    func goToNextStep() {
//        guard
//            let currentStep,
//            let index = index(of: currentStep),
//            index < flowSteps.count - 1
//        else {
//            return
//        }
//
//        let step = flowSteps[index + 1]
//        goToStep(step)
//    }

//    func goToPreviousStep() {
//        guard
//            let currentStep,
//            let index = index(of: currentStep),
//            index > 0
//        else {
//            return
//        }
//
//        let step = flowSteps[index - 1]
//        goToStep(step)
//    }
//
//    func goToStep(_ step: HotOnboardingFlowStep) {
//        currentStep = step
//    }
//
//    func index(of step: HotOnboardingFlowStep) -> Int? {
//        flowSteps.firstIndex(of: step)
//    }

//    func isStepFirst(_ step: HotOnboardingFlowStep) -> Bool {
//        flowSteps.first == step
//    }
}

// MARK: - HotOnboardingFlowRoutable

extension HotOnboardingViewModel: HotOnboardingFlowRoutable {
    func goNextStep() {
        currentStepIndex += 1
        leadingItem = currentStep?.navigation.leadingItem
    }

    func goPreviousStep() {
        currentStepIndex -= 1
        leadingItem = currentStep?.navigation.leadingItem
    }

    func openMain(userWalletModel: UserWalletModel) {
        coordinator?.onboardingDidFinish(userWalletModel: userWalletModel)
    }

    func openAccesCodeSkipAlert(onAllow: @escaping () -> Void) {}

    func openConfetti() {}

    func closeOnboarding() {}
}

// MARK: - HotOnboardingFlowNavigationDelegate

extension HotOnboardingViewModel: HotOnboardingFlowNavigationDelegate {
    func leadingItemChanged(to item: HotOnboardingFlowNavigation.ActionItem?) {
        leadingItem = item
    }
}
