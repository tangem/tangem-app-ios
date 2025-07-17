//
//  HotOnboardingAccessCodeCreateFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

final class HotOnboardingAccessCodeCreateFlowBuilder: HotOnboardingFlowBuilder {
    let hasProgressBar = true

    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?
    private weak var navigationDelegate: HotOnboardingFlowNavigationDelegate?

    private var bag: Set<AnyCancellable> = []

    init(
        userWalletModel: UserWalletModel,
        coordinator: HotOnboardingFlowRoutable,
        navigationDelegate: HotOnboardingFlowNavigationDelegate
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        self.navigationDelegate = navigationDelegate
    }

    func buildSteps() -> [HotOnboardingFlowStep] {
        [makeAccessCodeCreateStep(), makeDoneStep()]
    }
}

// MARK: - Steps maker

private extension HotOnboardingAccessCodeCreateFlowBuilder {
    func makeAccessCodeCreateStep() -> HotOnboardingFlowStep {
        let skipAction = HotOnboardingFlowNavigation.Action { [weak self] in
            self?.coordinator?.openAccesCodeSkipAlert(
                onAllow: {
                    self?.goNextStep()
                }
            )
        }

        let navigation = HotOnboardingFlowNavigation(
            title: Localization.accessCodeNavtitle,
            leadingItem: nil,
            trailingItem: .skip(skipAction)
        )

        let viewModel = HotOnboardingAccessCodeCreateViewModel(delegate: self)
        let content = { HotOnboardingAccessCodeCreateView(viewModel: viewModel) }

        let backAction = HotOnboardingFlowNavigation.Action {
            viewModel.resetState()
        }

        viewModel.$state
            .sink { [weak navigationDelegate] accessCodeState in
                switch accessCodeState {
                case .accessCode:
                    navigationDelegate?.leadingItemChanged(to: nil)
                case .confirmAccessCode:
                    navigationDelegate?.leadingItemChanged(to: .back(backAction))
                }
            }
            .store(in: &bag)

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }

    func changeAccessCodeNavigationTrailingItem(state: HotOnboardingAccessCodeCreateViewModel.State) {
        switch state {
        case .accessCode:
            navigationDelegate?.leadingItemChanged(to: nil)
        case .confirmAccessCode:
            let action = HotOnboardingFlowNavigation.Action {}
            navigationDelegate?.leadingItemChanged(to: .back(action))
        }
    }

    func makeDoneStep() -> HotOnboardingFlowStep {
        let navigation = HotOnboardingFlowNavigation(
            title: Localization.commonDone,
            leadingItem: nil,
            trailingItem: nil
        )

        let viewModel = HotOnboardingSuccessViewModel(
            type: .walletReady,
            onAppear: weakify(self, forFunction: HotOnboardingAccessCodeCreateFlowBuilder.openConfetti),
            onComplete: weakify(self, forFunction: HotOnboardingAccessCodeCreateFlowBuilder.closeOnboarding)
        )

        let content = { HotOnboardingSuccessView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }
}

// MARK: - Navigation

private extension HotOnboardingAccessCodeCreateFlowBuilder {
    func goNextStep() {
        coordinator?.goNextStep()
    }

    func openConfetti() {
        coordinator?.openConfetti()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingAccessCodeDelegate

extension HotOnboardingAccessCodeCreateFlowBuilder: HotOnboardingAccessCodeCreateDelegate {
    func isRequestBiometricsNeeded() -> Bool {
        true
    }

    func accessCodeComplete(accessCode: String) {
        // [REDACTED_TODO_COMMENT]
        goNextStep()
    }
}
