//
//  HotOnboardingSeedPhraseRevealStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemHotSdk

final class HotOnboardingSeedPhraseRevealStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseRevealViewModel

    init(context: MobileWalletContext) {
        viewModel = HotOnboardingSeedPhraseRevealViewModel(context: context)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseRevealView(viewModel: viewModel)
    }
}
