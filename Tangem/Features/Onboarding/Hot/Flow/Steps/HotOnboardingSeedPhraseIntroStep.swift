//
//  HotOnboardingSeedPhraseIntroStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class HotOnboardingSeedPhraseIntroStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseIntroViewModel

    init(delegate: HotOnboardingSeedPhraseIntroDelegate) {
        viewModel = HotOnboardingSeedPhraseIntroViewModel(delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseIntroView(viewModel: viewModel)
    }
}
