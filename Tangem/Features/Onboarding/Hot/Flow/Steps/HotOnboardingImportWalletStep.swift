//
//  HotOnboardingImportWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingImportWalletStep: HotOnboardingFlowStep {
    private let viewModel: OnboardingSeedPhraseImportViewModel

    init(delegate: SeedPhraseImportDelegate) {
        viewModel = OnboardingSeedPhraseImportViewModel(
            inputProcessor: SeedPhraseInputProcessor(),
            delegate: delegate
        )
    }

    override func build() -> any View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
