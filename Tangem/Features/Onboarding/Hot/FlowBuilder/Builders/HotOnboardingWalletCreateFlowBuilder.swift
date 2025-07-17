//
//  HotOnboardingWalletCreateFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class HotOnboardingWalletCreateFlowBuilder: HotOnboardingFlowBuilder {
    let hasProgressBar = false

    private weak var coordinator: HotOnboardingFlowRoutable?

    init(coordinator: HotOnboardingFlowRoutable) {
        self.coordinator = coordinator
    }

    func buildSteps() -> [HotOnboardingFlowStep] {
        [makeWalletCreateStep()]
    }
}

// MARK: - Steps maker

private extension HotOnboardingWalletCreateFlowBuilder {
    func makeWalletCreateStep() -> HotOnboardingFlowStep {
        let closeAction = HotOnboardingFlowNavigation.Action(
            closure: weakify(self, forFunction: HotOnboardingWalletCreateFlowBuilder.closeOnboarding)
        )

        let navigation = HotOnboardingFlowNavigation(
            title: .empty,
            leadingItem: .back(closeAction),
            trailingItem: nil
        )

        let viewModel = HotOnboardingCreateWalletViewModel(delegate: self)
        let content = { HotOnboardingCreateWalletView(viewModel: viewModel) }

        return HotOnboardingFlowStep(navigation: navigation, content: content)
    }
}

// MARK: - Navigation

private extension HotOnboardingWalletCreateFlowBuilder {
    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingCreateWalletDelegate

extension HotOnboardingWalletCreateFlowBuilder: HotOnboardingCreateWalletDelegate {
    func onCreateWallet() {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openMain(userWalletModel:)
    }
}
