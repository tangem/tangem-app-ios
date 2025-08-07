//
//  HotOnboardingRevealSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

final class HotOnboardingRevealSeedPhraseFlowBuilder: HotOnboardingFlowBuilder {
    private let userWalletModel: UserWalletModel
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        coordinator: HotOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let seedPhraseResolver = CommonHotOnboardingSeedPhraseResolver(userWalletModel: userWalletModel)
        let seedPhraseRevealStep = HotOnboardingSeedPhraseRevealStep(seedPhraseResolver: seedPhraseResolver)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: navBarCloseAction
            )
        flow.append(seedPhraseRevealStep)
    }
}

// MARK: - Navigation

private extension HotOnboardingRevealSeedPhraseFlowBuilder {
    func openNext() {
        next()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - Private methods

private extension HotOnboardingRevealSeedPhraseFlowBuilder {
    var navBarCloseAction: HotOnboardingFlowNavBarAction {
        HotOnboardingFlowNavBarAction.close(handler: { [weak self] in
            self?.closeOnboarding()
        })
    }
}
