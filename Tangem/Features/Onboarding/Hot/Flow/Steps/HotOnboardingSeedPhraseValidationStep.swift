//
//  HotOnboardingSeedPhraseValidationStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingSeedPhraseValidationStep: HotOnboardingFlowStep {
    private let viewModel: OnboardingSeedPhraseUserValidationViewModel

    init(seedPhraseResolver: HotOnboardingSeedPhraseResolver, onCreateWallet: @escaping () -> Void) {
        let words = seedPhraseResolver.validationWords
        viewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: words.second,
            seventhWord: words.seventh,
            eleventhWord: words.eleventh,
            createWalletAction: onCreateWallet
        ))
    }

    override func build() -> any View {
        OnboardingSeedPhraseUserValidationView(viewModel: viewModel)
    }
}
