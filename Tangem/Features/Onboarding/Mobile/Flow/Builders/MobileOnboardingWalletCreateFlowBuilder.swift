//
//  MobileOnboardingWalletCreateFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class MobileOnboardingCreateWalletFlowBuilder: MobileOnboardingFlowBuilder {
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(coordinator: MobileOnboardingFlowRoutable) {
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let createWalletStep = MobileOnboardingCreateWalletStep(delegate: self)
            .configureNavBar(
                leadingAction: .back(handler: { [weak self] in
                    self?.closeOnboarding()
                })
            )
        append(step: createWalletStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingCreateWalletFlowBuilder {
    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingCreateWalletDelegate

extension MobileOnboardingCreateWalletFlowBuilder: MobileOnboardingCreateWalletDelegate {
    func onCreateWallet(userWalletModel: UserWalletModel) {
        Analytics.log(.onboardingFinished)
        coordinator?.openMain(userWalletModel: userWalletModel)
    }
}
