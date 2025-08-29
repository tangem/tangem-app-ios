//
//  MobileOnboardingSeedPhraseIntroStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

final class MobileOnboardingSeedPhraseIntroStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseIntroViewModel

    init(delegate: MobileOnboardingSeedPhraseIntroDelegate) {
        viewModel = MobileOnboardingSeedPhraseIntroViewModel(delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseIntroView(viewModel: viewModel)
    }
}
