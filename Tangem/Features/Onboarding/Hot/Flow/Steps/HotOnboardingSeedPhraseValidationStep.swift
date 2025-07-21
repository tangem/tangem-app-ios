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

    init(seedPhraseWords: [String], onCreateWallet: @escaping () -> Void) {
        viewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: seedPhraseWords[1],
            seventhWord: seedPhraseWords[6],
            eleventhWord: seedPhraseWords[10],
            createWalletAction: onCreateWallet
        ))
    }

    override func build() -> any View {
        OnboardingSeedPhraseUserValidationView(viewModel: viewModel)
    }
}
