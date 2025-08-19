//
//  HotOnboardingSeedPhraseValidationStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation
import TangemMobileWalletSdk

final class HotOnboardingSeedPhraseValidationStep: HotOnboardingFlowStep {
    private let viewModel: HotOnboardingSeedPhraseValidationViewModel

    init(userWalletId: UserWalletId, delegate: HotOnboardingSeedPhraseValidationDelegate) {
        viewModel = HotOnboardingSeedPhraseValidationViewModel(userWalletId: userWalletId, delegate: delegate)
    }

    override func build() -> any View {
        HotOnboardingSeedPhraseValidationView(viewModel: viewModel)
    }
}
