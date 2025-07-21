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

    init(delegate: HotOnboardingSeedPhraseRevealDelegate) {
        viewModel = HotOnboardingSeedPhraseRevealViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseRevealView(viewModel: viewModel)
    }
}
