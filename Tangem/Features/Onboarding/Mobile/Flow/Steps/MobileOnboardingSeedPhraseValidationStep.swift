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

    init(userWalletId: UserWalletId, delegate: MobileOnboardingSeedPhraseValidationDelegate) {
        viewModel = MobileOnboardingSeedPhraseValidationViewModel(userWalletId: userWalletId, delegate: delegate)
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseValidationView(viewModel: viewModel)
    }
}
