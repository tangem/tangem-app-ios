//
//  MobileOnboardingSeedPhraseRevealStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseRevealStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseRevealViewModel

    init(context: MobileWalletContext) {
        viewModel = MobileOnboardingSeedPhraseRevealViewModel(context: context)
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseRevealView(viewModel: viewModel)
    }
}
