//
//  HotOnboardingWalletCreateFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class HotOnboardingCreateWalletFlowBuilder: HotOnboardingFlowBuilder {
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(coordinator: HotOnboardingFlowRoutable) {
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let createWalletStep = HotOnboardingCreateWalletStep(delegate: self)
        flow.append(createWalletStep)
    }
}

// MARK: - Navigation

private extension HotOnboardingCreateWalletFlowBuilder {
    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - HotOnboardingCreateWalletDelegate

extension HotOnboardingCreateWalletFlowBuilder: HotOnboardingCreateWalletDelegate {
    func onCreateWallet() {
        // [REDACTED_TODO_COMMENT]
        // coordinator?.openMain(userWalletModel:)
    }
}
