//
//  MobileOnboardingRevealSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemMobileWalletSdk

final class MobileOnboardingRevealSeedPhraseFlowBuilder: MobileOnboardingFlowBuilder {
    private let context: MobileWalletContext
    private weak var coordinator: MobileOnboardingFlowRoutable?

    init(context: MobileWalletContext, coordinator: MobileOnboardingFlowRoutable) {
        self.context = context
        self.coordinator = coordinator
        super.init(hasProgressBar: false)
    }

    override func setupFlow() {
        let seedPhraseRevealStep = MobileOnboardingSeedPhraseRevealStep(
            context: context,
            delegate: self
        )
        append(step: seedPhraseRevealStep)
    }
}

// MARK: - Navigation

private extension MobileOnboardingRevealSeedPhraseFlowBuilder {
    func openNext() {
        next()
    }

    func closeOnboarding() {
        coordinator?.closeOnboarding()
    }
}

// MARK: - MobileOnboardingSeedPhraseRevealDelegate

extension MobileOnboardingRevealSeedPhraseFlowBuilder: MobileOnboardingSeedPhraseRevealDelegate {
    func onSeedPhraseRevealClose() {
        closeOnboarding()
    }
}
