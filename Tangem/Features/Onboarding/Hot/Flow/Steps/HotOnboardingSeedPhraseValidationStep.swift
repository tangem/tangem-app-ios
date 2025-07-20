//
//  HotOnboardingSeedPhraseValidationStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingSeedPhraseValidationStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: OnboardingSeedPhraseUserValidationViewModel

    init(seedPhraseWords: [String], onCreateWallet: @escaping () -> Void) {
        viewModel = OnboardingSeedPhraseUserValidationViewModel(validationInput: .init(
            secondWord: seedPhraseWords[1],
            seventhWord: seedPhraseWords[6],
            eleventhWord: seedPhraseWords[10],
            createWalletAction: onCreateWallet
        ))
    }

    func build() -> some View {
        OnboardingSeedPhraseUserValidationView(viewModel: viewModel)
    }
}
