//
//  HotOnboardingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol HotOnboardingRoutable: OnboardingRoutable {}

final class HotOnboardingViewModel: ObservableObject {
    @Published var currentStep: HotOnboardingStep

    var navigationBarTitle: String {
        currentStep.navigationTitle
    }

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height

    lazy var createWalletViewModel = HotOnboardingCreateWalletViewModel(
        onCreate: { [weak self] in
            self?.createHotWallet()
        }
    )

    private let input: HotOnboardingInput
    private weak var coordinator: HotOnboardingRoutable?

    init(input: HotOnboardingInput, coordinator: HotOnboardingRoutable) {
        self.input = input
        self.coordinator = coordinator
        currentStep = input.steps.first ?? .createWallet
    }
}

// MARK: - Internal methods

extension HotOnboardingViewModel {
    func backButtonAction() {
        switch currentStep {
        case .createWallet:
            closeOnboarding()
        case .importWallet:
            closeOnboarding()
        }
    }

    func onSupportTap() {}
}

// MARK: - Steps navigation

private extension HotOnboardingViewModel {
    func goToNextStep() {
        switch currentStep {
        case .createWallet:
            break // [REDACTED_TODO_COMMENT]
        case .importWallet:
            break // [REDACTED_TODO_COMMENT]
        }
    }

    func goToStep(_ step: HotOnboardingStep) {
        currentStep = step
    }
}

// MARK: - Private methods

private extension HotOnboardingViewModel {
    func createHotWallet() {
        goToNextStep()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}
