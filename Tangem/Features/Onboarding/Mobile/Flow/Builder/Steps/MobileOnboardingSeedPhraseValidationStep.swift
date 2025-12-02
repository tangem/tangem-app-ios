//
//  MobileOnboardingSeedPhraseValidationStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk

final class MobileOnboardingSeedPhraseValidationStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseValidationViewModel

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingSeedPhraseValidationDelegate
    ) {
        viewModel = MobileOnboardingSeedPhraseValidationViewModel(
            userWalletModel: userWalletModel,
            source: source,
            delegate: delegate
        )
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseValidationView(viewModel: viewModel)
    }
}
