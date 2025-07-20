//
//  HotOnboardingRevealSeedPhraseFlowBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

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
            flow.append(validateAccessCodeStep)
        }

        let seedPhraseRevealStep = HotOnboardingSeedPhraseRevealStep(delegate: self)
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
    func getSeedPhraseWords() -> [String] {
        // [REDACTED_TODO_COMMENT]
        return [
            "brother", "embrace", "piano", "income", "feature", "real",
            "bicycle", "stairs", "glimpse", "fan", "salon", "elder",
            // brother embrace piano income feature real bicycle stairs glimpse fan salon elder
        ]
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

// MARK: - HotOnboardingSeedPhraseRevealDelegate

extension HotOnboardingRevealSeedPhraseFlowBuilder: HotOnboardingSeedPhraseRevealDelegate {
    func getSeedPhrase() -> [String] {
        getSeedPhraseWords()
    }
}
