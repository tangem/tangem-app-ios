//
//  HotOnboardingRevealSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemMobileWalletSdk

final class HotOnboardingRevealSeedPhraseFlowBuilder: HotOnboardingFlowBuilder {
    private let context: MobileWalletContext
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(context: MobileWalletContext, coordinator: HotOnboardingFlowRoutable) {
        self.context = context
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        let seedPhraseRevealStep = HotOnboardingSeedPhraseRevealStep(context: context)
            .configureNavBar(
                title: Localization.commonBackup,
                leadingAction: navBarCloseAction
            )
        append(step: seedPhraseRevealStep)
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
