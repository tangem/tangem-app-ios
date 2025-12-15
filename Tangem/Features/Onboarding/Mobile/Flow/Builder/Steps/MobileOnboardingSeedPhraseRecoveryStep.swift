//
//  MobileOnboardingSeedPhraseRecoveryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

final class MobileOnboardingSeedPhraseRecoveryStep: MobileOnboardingFlowStep {
    private let viewModel: MobileOnboardingSeedPhraseRecoveryViewModel

    init(
        userWalletModel: UserWalletModel,
        source: MobileOnboardingFlowSource,
        delegate: MobileOnboardingSeedPhraseRecoveryDelegate
    ) {
        viewModel = MobileOnboardingSeedPhraseRecoveryViewModel(
            userWalletModel: userWalletModel,
            source: source,
            delegate: delegate
        )
    }

    override func build() -> any View {
        MobileOnboardingSeedPhraseRecoveryView(viewModel: viewModel)
    }
}
