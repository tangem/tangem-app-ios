//
//  HotOnboardingSeedPhraseRevealStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingSeedPhraseRevealStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseRevealViewModel

    init(seedPhraseResolver: HotOnboardingSeedPhraseResolver) {
        viewModel = HotOnboardingSeedPhraseRevealViewModel(seedPhraseResolver: seedPhraseResolver)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseRevealView(viewModel: viewModel)
    }
}
