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
    private let needAccessCodeValidation: Bool
    private weak var coordinator: HotOnboardingFlowRoutable?

    init(
        userWalletModel: UserWalletModel,
        needAccessCodeValidation: Bool,
        coordinator: HotOnboardingFlowRoutable
    ) {
        self.userWalletModel = userWalletModel
        self.needAccessCodeValidation = needAccessCodeValidation
        self.coordinator = coordinator
        super.init()
    }

    override func setupFlow() {
        if needAccessCodeValidation {
            let manager = CommonHotAccessCodeManager(userWalletModel: userWalletModel, delegate: self)
            let validateAccessCodeStep = HotOnboardingValidateAccessCodeStep(manager: manager)
                .configureNavBar(leadingAction: navBarCloseAction)
            flow.append(validateAccessCodeStep)
        }

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

// MARK: - CommonHotAccessCodeManagerDelegate

extension HotOnboardingRevealSeedPhraseFlowBuilder: CommonHotAccessCodeManagerDelegate {
    func handleAccessCodeSuccessful(userWalletModel: UserWalletModel) {
        openNext()
    }

    func handleAccessCodeDelete(userWalletModel: UserWalletModel) {
        // [REDACTED_TODO_COMMENT]
    }
}
