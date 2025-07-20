//
//  HotOnboardingImportWalletStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct HotOnboardingImportWalletStep: HotOnboardingFlowStep {
    var transformations: [TransformationModifier<AnyView>] = []

    private let viewModel: OnboardingSeedPhraseImportViewModel

    init(delegate: SeedPhraseImportDelegate) {
        viewModel = OnboardingSeedPhraseImportViewModel(
            inputProcessor: SeedPhraseInputProcessor(),
            delegate: delegate
        )
    }

    func build() -> some View {
        OnboardingSeedPhraseImportView(viewModel: viewModel)
    }
}
